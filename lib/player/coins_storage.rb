require 'lib/player/redis_mapper'

module Player
  class CoinsStorage

    include RedisMapper

    def initialize(player_id)
      @player_id = player_id
      @redis_key = ['players', @player_id].join(':')
      restore_from_redis(@redis_key, { coins_storage_amount: 1000 }){ |v| v.to_i }
    end

    def full?
      @coins_storage_amount >= @capacity
    end

    def compute!(level)
      @capacity = Storage::GameData.coins_storage_capacity(level)
      save!
    end

    def remains
      [@capacity - @coins_storage_amount, 0].max
    end

    def put_coins(count)
      @coins_storage_amount += count
      if @coins_storage_amount >= @capacity
        @coins_storage_amount = @capacity
      end
      save!
    end

    def make_payment(count)
      if @coins_storage_amount >= count
        @coins_storage_amount -= count
        save!
        return true
      end

      false
    end

    def to_hash
      {
        amount: @coins_storage_amount,
        capacity: @capacity
      }
    end

    def save!
      save_to_redis(@redis_key, [:coins_storage_amount])
    end

  end
end
