require 'lib/abstract_actor'
require 'lib/player/redis_mapper'
require 'lib/player/score'
require 'lib/player/coins_storage'
require 'lib/player/coins_mine'
require 'lib/player/mana_storage'

module Player
  class Actor < AbstractActor

    # include RedisMapper

    def initialize(id, email, username)
      @id, @email, @username = id, email, username

      @coins_storage = CoinsStorage.new(@id)
      @coins_storage.compute!(2)

      @coins_mine = CoinsMine.new(@id)
      @coins_mine.compute!(2)

      @score = Score.new(@id)

      @mana_storage = ManaStorage.new(@id)
      @mana_storage.compute_at_shard!(@score.current_level)
    end

    def act message, sender_uid

      puts "PLAYER!!: #{message.inspect}"

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