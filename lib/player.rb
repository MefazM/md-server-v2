require 'lib/abstract_actor'
require 'lib/player/redis_mapper'
require 'lib/player/score'
require 'lib/player/coins_storage'
require 'lib/player/coins_mine'
require 'lib/player/mana_storage'
require 'lib/player/units'
require 'lib/player/buildings'
require 'lib/player/authorisation'
require 'lib/player/unique_connection'
require 'lib/player/actions_perform'

require 'server/actions_headers'

module Player

  include UniqueConnection
  include Authorisation
  include ActionsPerform

  map_action Request::LOGIN, as: :process_login_action
  map_action Request::GAME_DATA, as: :send_gamedata_action
  map_action Request::HARVESTING, as: :make_harvesting, authorized: true

  # map_action :player, as: :process_player_action
  # map_action :new_battle, as: :process_lobby_action
  # map_action :battle_start, as: :process_battle_action
  # map_action :lobby_data, as: :process_lobby_action
  # map_action :spawn_unit, as: :process_battle_action
  # map_action :unit_production_task, as: :process_player_action, authorized: true
  # map_action :spell_cast, as: :process_battle_action
  # map_action :response_battle_invite, as: :process_lobby_action
  # map_action :ping, as: :send_pong_action
  # map_action :building_production_task, as: :process_player_action, authorized: true
  # map_action :do_harvesting, as: :process_player_action, authorized: true
  # map_action :current_mine, as: :process_player_action, authorized: true
  # map_action :reload_gd, as: :process_sytem_action

  def kill!
    # persist player
    # kill soket
    # destroy object

  end

  def make_harvesting(_)
    puts('make_harvesting')
  end

  def process_login_action(login_data)
    authorise!(login_data)
    make_uniq!

    @coins_storage = CoinsStorage.new(@id)
    @coins_storage.compute!(2)

    @coins_mine = CoinsMine.new(@id)
    @coins_mine.compute!(2)

    @score = Score.new(@id)

    @mana_storage = ManaStorage.new(@id)
    @mana_storage.compute_at_shard!(@score.current_level)

    @buildings = Buildings.new(@id)
    @units = Units.new(@id)


    send_data(['authorised', initialization_data])
  end

  def send_gamedata_action(data)
    send_data ['game_data', Storage::GameData.initialization_data]
  end

  def initialization_data
    {
      player_data: {
        coins_storage: @coins_storage.to_hash,
        coins_mine: @coins_mine.to_hash,
        mana_storage: @mana_storage.to_hash,
        score: @score.to_hash,
        buildings: {},
        units: {
          # restore unit production queue on client
          queue: {},
          ready: {},
        },
      },

      start_scene: :world
    }
  end

  private

  def create
  end
end
