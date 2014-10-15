require 'lib/abstract_actor'
require 'lib/player/redis_mapper'
require 'lib/player/score'
require 'lib/player/coins_storage'
require 'lib/player/coins_mine'
require 'lib/player/mana_storage'
require 'lib/player/units'
require 'lib/player/buildings'

module Player
  class Actor < AbstractActor

    # include RedisMapper

    attr_accessor :connection_uid

    def initialize(id, email, username, connection_uid)
      @id, @email, @username, @connection_uid = id, email, username, connection_uid

      @coins_storage = CoinsStorage.new(@id)
      @coins_storage.compute!(2)

      @coins_mine = CoinsMine.new(@id)
      @coins_mine.compute!(2)

      @score = Score.new(@id)

      @mana_storage = ManaStorage.new(@id)
      @mana_storage.compute_at_shard!(@score.current_level)

      @buildings = Buildings.new(@id)
      @units = Units.new(@id)
    end

  # def act(action, data, sender_uid)
  #   puts "Player##{@id} resived: #{action}, #{data}, #{sender_uid}"

  #   method(action).call(data, sender_uid)

  #   rescue Exception => e
  #     TheLogger.error <<-MSG
  #       Can't act action: [#{action}] for player id: [#{@id}]
  #       #{e}
  #       #{e.backtrace.join("\n")}
  #     MSG
  # end

    def do_harvesting(data)
      puts(data.inspect)
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

  end
end