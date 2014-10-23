require 'lib/player/redis_mapper'

module Player
  class ManaStorage

    include RedisMapper

    def initialize(player_id)
      @player_id = player_id
      @redis_key = ['players', @player_id].join(':')

      restore_from_redis(@redis_key, {
        last_mana_compute_time: Time.now.to_i,
        mana_storage_amount: 0
      }){|v| v.to_i }
    end

    def compute_at_shard!(level)
      compute!(level, :income_at_shard)
    end

    def compute_at_battle!(level)
      compute!(level, :income_at_battle)
    end

    def to_hash
      {
        amount: @coins_storage_amount,
        capacity: @capacity
      }
    end

    def decreasre(value)
      # compute_mana_storage
      if @mana_storage_amount >= value
        @mana_storage_amount -= value
        # send_sync_mana_storage
        return true
      end

      false
    end

    def save!

    end

    def to_hash
      {
        capacity: @capacity,
        income: @income,
        amount: @mana_storage_amount
      }
    end

    private

    def compute!(level, income_type)
      current_time = Time.now.to_i
      d_time = current_time - @last_mana_compute_time
      @last_mana_compute_time = current_time

      settings = Storage::GameData.mana_storage level

      @capacity = settings[:capacity]
      @income = settings[income_type]
      @mana_storage_amount += d_time * @income

      max_capacity = @capacity
      if @mana_storage_amount >= max_capacity
        @mana_storage_amount = max_capacity
      end
    end

  end
end