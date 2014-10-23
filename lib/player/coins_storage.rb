require 'lib/player/redis_mapper'

module Player
  class CoinsStorage

    include RedisMapper

    def initialize(player_id)
      @player_id = player_id
      @redis_key = ['players', @player_id].join(':')

      restore_from_redis(@redis_key, { coins_storage_amount: 0 }){ |v| v.to_i }
    end

    def full?
      @coins_storage_amount >= @capacity
    end

    def compute!(level)
      # level = @buildings[@storage_building_uid] || 0
      @capacity =  Storage::GameData.coins_storage_capacity level
    end

    def remains
      [@capacity - @coins_storage_amount, 0].max
    end

    def put_coins(count)

      @coins_storage_amount += count

      if @coins_storage_amount >= @capacity
        @coins_storage_amount = @capacity
      end
    end

    def make_payment(count)
      if @coins_storage_amount >= count
        @coins_storage_amount -= count
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

    end

  end
end
