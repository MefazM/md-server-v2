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

    def decrease(value)
      if @mana_storage_amount >= value
        @mana_storage_amount -= value

        return true
      end

      false
    end

    def save!
      save_to_redis(@redis_key, [:last_mana_compute_time, :mana_storage_amount])
    end

    def to_hash

      puts("#{@capacity} #{@income} #{@mana_storage_amount}")

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

      if @mana_storage_amount >= @capacity
        @mana_storage_amount = @capacity
      end
    end

  end
end