require 'lib/player/redis_mapper'
require 'lib/player/score'
require 'lib/player/coins_storage'
require 'lib/player/coins_mine'
require 'lib/player/mana_storage'
require 'lib/player/units'
require 'lib/player/buildings'
require 'lib/player/authorisation'
require 'lib/player/requests_dispatcher'
require 'lib/player/send_actions'
require 'lib/battle/battle'
require 'lib/player/lobby'
require 'lib/ai_generator'

module Player
  SAVE_TO_REDIS_INTERVAL = 20

  include Authorisation
  include RequestsDispatcher
  include SendActions

  include Lobby::Inviteable
  include Battle::React

  map_requests Receive::LOGIN, as: :process_login_action
  map_requests Receive::GAME_DATA, as: :process_gamedata_action
  map_requests Receive::HARVESTING, as: :process_harvesting, authorized: true
  map_requests Receive::PING, as: :process_pong_action, authorized: true
  map_requests Receive::CONSTUCT_BUILDING, as: :construct_building, authorized: true
  map_requests Receive::CONSTUCT_UNIT, as: :construct_unit, authorized: true
  map_requests Receive::UPDATE_LOBBY_DATA, as: :generate_lobby, authorized: true


  map_requests Receive::INVITE_OPPONENT_TO_BATTLE, as: :invite_opponent_to_battle, authorized: true
  map_requests Receive::CREATE_AI_BATTLE, as: :create_ai_battle, authorized: true
  map_requests Receive::RESPONSE_INVITATION_TO_BATTLE, as: :response_invitation_to_battle, authorized: true

  map_requests Receive::READY_TO_BATTLE, as: :ready_to_battle, authorized: true
  map_requests Receive::CAST_SPELL, as: :cast_spell, authorized: true
  map_requests Receive::SPAWN_UNIT, as: :spawn_unit, authorized: true

  map_requests Receive::BATTLE_CUSTOM_ACTION, as: :battle_custom_action, authorized: true

  def process_login_action(login_data)
    authorise!(login_data)

    restore_player
  end

  def uid
    @player_id.to_s
  end

  def process_harvesting
    earned = @coins_mine.harvest(@coins_storage.remains)
    @coins_storage.put_coins(earned)

    sync_coins(earned)
  end

  def process_gamedata_action
    send_game_data
  end

  def process_pong_action
    send_pong
  end

  def save_player_timer
    save!
    # Run timer once more time
    after(:save_player_timer, nil, SAVE_TO_REDIS_INTERVAL)
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

  def generate_lobby
    players = Lobby.players(player_rate).delete_if{|player| player[:uid] == uid }
    send_lobby_data(players, AiGenerator.generate_all(@score.current_level))
  end

  def create_ai_battle(ai_type)
    ai_data = AiGenerator.generate(ai_type, @score.current_level)

    Battle.create_ai_battle(battle_snapshot, ai_data)
  end

  def invite_opponent_to_battle(opponent_uid)
    Lobby.create_invite(uid, opponent_uid)
  end

  def response_invitation_to_battle(data)
    Lobby.process_invite(uid, data)
  end

  def ready_to_battle
    Battle.set_opponent_ready(uid)
  end

  def cast_spell(data)
    prototype = Storage::GameData.spell_data(data[:name])

    @mana_storage.compute_at_battle!(@buildings.coins_mine_level)

    if prototype && @mana_storage.decrease(prototype[:mana_cost])
      Battle.cast_spell(uid, data)
    else
      TheLogger.error("Can'p perform spell - #{data[:name]}!")

      send_notification(:low_mana)
    end

    sync_mana
  end

  def spawn_unit(unit_uid)
    Battle.spawn_unit(uid, unit_uid)
  end

  def kill!
    save!
    @alive = false
    close_connection_after_writing
  end

  def inspect
    "<Player id: #{@player_id}>"
  end

  def sync_after_battle(data)
    battle_results = data[uid]

    @units.mass_remove_units(battle_results[:lost_units])
    sync_units

    @coins_storage.put_coins(battle_results[:coins])
    sync_coins

    @score.increase(battle_results[:score])
    sync_score

    @mana_storage.compute_at_battle!(@buildings.coins_mine_level)
    sync_mana

    send_finish_battle(battle_results)
  end

  def battle_custom_action(action_name)
    Battle.call_custom_action(uid, action_name)
  end

  private

  def restore_player

    Reactor.link(self)

    @buildings = Buildings.new(@player_id)
    @buildings.restore_queue.each{|task| after(:building_update_ready, *task) }

    send_authorised
    send_game_data

    @units = Units.new(@player_id)
    @units.restore_queue.each{|task| after(:unit_production_ready, *task) }

    sync_units

    @coins_storage = CoinsStorage.new(@player_id)
    @coins_storage.compute!(@buildings.coins_storage_level)

    @coins_mine = CoinsMine.new(@player_id)
    @coins_mine.compute!(@buildings.coins_mine_level)

    sync_coins

    @score = Score.new(@player_id)

    sync_score

    @mana_storage = ManaStorage.new(@player_id)

    unless tutorial_complited?
      if Battle.exists?(uid)
        Battle.destroy_battle!(uid)
      end

      @mana_storage.compute_at_battle!(@score.current_level)
      sync_mana

      Battle.create_tutorial_battle(battle_snapshot)
    else
      if Battle.exists?(uid)
        @mana_storage.compute_at_battle!(@score.current_level)
        sync_mana

        Battle.restore_opponent(uid)
      else
        @mana_storage.compute_at_shard!(@score.current_level)
        sync_mana

        register_in_lobby

        start_game_scene(:world)
      end
    end

    after(:save_player_timer, nil, SAVE_TO_REDIS_INTERVAL)
  end

  def tutorial_complited?
    false
  end

  def player_rate
    0
  end

  def save!

    TheLogger.info("Save player: #{uid}...")

    @coins_storage.save!
    @coins_mine.save!
    @score.save!
    @mana_storage.save!
    @buildings.save!
    @units.save!
  end
end
