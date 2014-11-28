require 'lib/player/redis_mapper'
require 'lib/player/score'
require 'lib/player/coins_storage'
require 'lib/player/coins_mine'
require 'lib/player/mana_storage'
require 'lib/player/units'
require 'lib/player/buildings'
require 'lib/player/authorisation'
require 'lib/player/requests_dispatcher'
require 'server/actions_headers'
require 'lib/player/send_actions'
require 'lib/battle/director'
require 'lib/player/lobby'

module Player
  SAVE_TO_REDIS_INTERVAL = 5

  include Authorisation
  include RequestsDispatcher
  include SendActions

  include Lobby::Inviteable

  map_requests Receive::LOGIN, as: :process_login_action
  map_requests Receive::GAME_DATA, as: :process_gamedata_action
  map_requests Receive::HARVESTING, as: :process_harvesting, authorized: true
  map_requests Receive::PING, as: :process_pong_action, authorized: true
  map_requests Receive::CONSTUCT_BUILDING, as: :construct_building, authorized: true
  map_requests Receive::CONSTUCT_UNIT, as: :construct_unit, authorized: true
  map_requests Receive::UPDATE_LOBBY_DATA, as: :generate_lobby, authorized: true

  map_requests Receive::INVITE_OPPONENT_TO_BATTLE, as: :invite_opponent_to_battle, authorized: true
  map_requests Receive::RESPONSE_INVITATION_TO_BATTLE, as: :response_invitation_to_battle, authorized: true

  def process_login_action(login_data)
    authorise!(login_data)

    restore_player

    send_authorised
    send_game_data

    sync_units
    sync_coins
    sync_score
    sync_mana

    start_game_scene(:world)
  end

  def uid
    @player_id.to_s
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
    # after(SAVE_TO_REDIS_INTERVAL, [:save_player_timer, nil])
  end

  def construct_building(building_uid)
    if @buildings.updateable?(building_uid)
      update = @buildings.update_data(building_uid)

      if @coins_storage.make_payment(update[:price])

        @buildings.enqueue(update)

        after(:building_update_ready, update[:uid], update[:production_time])

        sync_building(update, false)
        sync_coins
      else

        send_notification(:low_cash)
      end
    end
  end

  def building_update_ready(building_uid)
    updated = @buildings.complite(building_uid)
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
    info = Storage::GameData.unit(unit_uid)
    building_uid = info[:depends_on_building_uid]
    building_level = info[:depends_on_building_level]

    if @buildings.exists?(building_uid, building_level)
      if @coins_storage.make_payment(info[:price])

        if @units.enqueue(info)
          after(:unit_production_ready, unit_uid, info[:production_time])
        end

        sync_units
        sync_coins
      else
        send_notification(:low_cash)
      end
    end
  end

  def unit_production_ready(unit_uid)
    info = Storage::GameData.unit(unit_uid)
    next_taks = @units.complite(info)

    after(:unit_production_ready, *next_taks) if next_taks

    sync_units
  end

  def generate_lobby(data)
    players = Lobby.players(player_rate).delete_if{|player| player[0] == uid }
    send_lobby_data(Lobby.players(player_rate), Lobby.generate_ai(@score.current_level))
  end

  def invite_opponent_to_battle(data)
    puts(data.inspect)

    if data[:ai]
      create_ai_battle(data[:uid])
    else
      invite_to_battle(data[:uid])
    end
  end

  def response_invitation_to_battle(data)
    Lobby.process_invite(uid, data)
  end

  def kill!
    save!
    @alive = false
    close_connection_after_writing
  end

  def inspect
    "<Player id: #{@player_id}>"
  end

  private

  def restore_player

    Reactor.link(self)

    @buildings = Buildings.new(@player_id)
    @buildings.restore_queue.each{|task| after(:building_update_ready, *task) }

    @coins_storage = CoinsStorage.new(@player_id)
    @coins_storage.compute!(@buildings.coins_storage_level)

    @coins_mine = CoinsMine.new(@player_id)
    @coins_mine.compute!(@buildings.coins_mine_level)

    @score = Score.new(@player_id)

    @mana_storage = ManaStorage.new(@player_id)
    @mana_storage.compute_at_shard!(@score.current_level)

    @units = Units.new(@player_id)
    @units.restore_queue.each{|task| after(:unit_production_ready, *task) }

    register_in_lobby

    # after(SAVE_TO_REDIS_INTERVAL, [:save_player_timer, nil])
  end

  def player_rate
    0
  end

  def save!
    @coins_storage.save!
    @coins_mine.save!
    @score.save!
    @mana_storage.save!
    @buildings.save!
    @units.save!
  end
end
