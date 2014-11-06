require 'lib/player/redis_mapper'
require 'lib/player/score'
require 'lib/player/coins_storage'
require 'lib/player/coins_mine'
require 'lib/player/mana_storage'
require 'lib/player/units'
require 'lib/player/buildings'
require 'lib/player/authorisation'
require 'lib/player/unique_connection'
require 'lib/player/requests_dispatcher'
require 'server/actions_headers'
require 'lib/player/send_actions'
require 'lib/battle/director'

module Player
  SAVE_TO_REDIS_INTERVAL = 360

  include UniqueConnection
  include Authorisation
  include RequestsDispatcher
  include SendActions

  map_requests Receive::LOGIN, as: :process_login_action
  map_requests Receive::GAME_DATA, as: :process_gamedata_action
  map_requests Receive::HARVESTING, as: :process_harvesting, authorized: true
  map_requests Receive::PING, as: :process_pong_action, authorized: true
  map_requests Receive::CONSTUCT_BUILDING, as: :construct_building, authorized: true
  map_requests Receive::CONSTUCT_UNIT, as: :construct_unit, authorized: true


  def process_login_action(login_data)
    authorise!(login_data)
    make_uniq!
    restore_player

    send_authorised
    send_game_data

    sync_coins
    sync_score
    sync_mana

    start_game_scene(:world)
  end

  def process_harvesting(data)
    earned = @coins_mine.harvest(@coins_storage.remains)
    @coins_storage.put_coins(earned)

    sync_coins(earned)
  end

  def process_gamedata_action(data)
    send_game_data
  end

  def process_pong_action(data)
    send_pong
  end

  def save_player_timer(data = nil)
    save!
    # Run timer once more time
    Overlord.perform_after(SAVE_TO_REDIS_INTERVAL, [@uid, :save_player_timer, nil])
  end

  def construct_building(building_uid)
    if @buildings.updateable?(building_uid)
      update = @buildings.update_data(building_uid)

      if @coins_storage.make_payment(update[:price])
        @buildings.enqueue(update)

        period = update[:production_time]
        Overlord.perform_after(period, [@uid, :building_update_ready, building_uid])

        sync_building(update, false)
        sync_coins
      else

        send_notification( :low_cash )
      end
    end
  end

  def building_update_ready(building_uid)
    updated = @buildings.complite_update(building_uid)
    if updated
      #TODO: refactor this case
      case updated[:uid]
      when Storage::GameData.coin_generator_uid

      when Storage::GameData.storage_building_uid
        @coins_storage.compute!(@buildings.coins_storage_level)
      end

      sync_building(updated, true)
    end
  end

  def construct_unit(unit_uid)
    unit_data = Storage::GameData.unit(unit_uid)

    building_uid = unit_data[:depends_on_building_uid]
    building_level = unit_data[:depends_on_building_level]

    if @buildings.exists?(building_uid, building_level)
      if @coins_storage.make_payment(unit_data[:price])

        group_by = unit_data[:depends_on_building_uid]
        if @units.group_not_enqueued?(group_by)
          period = unit_data[:production_time]
          Overlord.perform_after(period, [@uid, :unit_production_ready, unit_uid])
        end

        @units.enqueue(unit_data)

        send_new_unit_task(unit_data)
        sync_coins

      else
        send_notification( :low_cash )
      end
    end
  end

  def unit_production_ready(unit_uid)
    unit_data = Storage::GameData.unit(unit_uid)

    @units.complite_task(unit_data)

    group_by = unit_data[:depends_on_building_uid]
    uid_uid, task = @units.group_next_task(group_by)

    if task
      period = task[:construction_time]
      Overlord.perform_after(period, [@uid, :unit_production_ready, uid_uid])
    end

    send_unit_task_ready(unit_data)
  end

  def kill!
    save!
    close_connection_after_writing
  end

  private

  def restore_player
    @buildings = Buildings.new(@player_id)

    @coins_storage = CoinsStorage.new(@player_id)
    @coins_storage.compute!(@buildings.coins_storage_level)

    @coins_mine = CoinsMine.new(@player_id)
    @coins_mine.compute!(@buildings.coins_mine_level)

    @score = Score.new(@player_id)

    @mana_storage = ManaStorage.new(@player_id)
    @mana_storage.compute_at_shard!(@score.current_level)

    @units = Units.new(@player_id)
    #TODO: refactor
    @buildings.queue.each do |uid, update|
      time_left = update[:construction_time] - (Time.now.to_i - update[:adding_time])
      if time_left < 0
        building_update_ready(uid)
      else
        Overlord.perform_after( time_left, [@uid, :building_update_ready, update[:uid]])
      end
    end

    Overlord.perform_after(SAVE_TO_REDIS_INTERVAL, [@uid, :save_player_timer, nil])
  end

  def save!
    @coins_storage.save!
    @coins_mine.save!
    @score.save!
    @mana_storage.save!
    @buildings.save!
  end

end
