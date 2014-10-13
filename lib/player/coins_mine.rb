require 'lib/player/redis_mapper'

module Player
  class CoinsMine

    include RedisMapper

    def initialize(player_id)
      @player_id = player_id
      @redis_key = ['players', @player_id].join(':')

      restore_from_redis(@redis_key, {
        last_harvest_time: Time.now.to_i,
        coins_mine_amount: 0
      }) {|v| v.to_i }
    end

    def compute!(level)
      # level = @buildings[Storage::GameData.coin_generator_uid] || 0
      data = Storage::GameData.coins_harvester level

      @income = data[:amount]
      @capacity = data[:harvest_capacity]
    end

    def harvest(max_earned)
      current_time = Time.now.to_i

      d_time = current_time - @last_harvest_time
      @last_harvest_time = current_time

      earned = (d_time * @income).to_i

      @coins_mine_amount += earned
      @coins_mine_amount = [@coins_mine_amount, @capacity].min

      left = @coins_mine_amount - earned

      if left > 0
        earned = max_earned
        @coins_mine_amount = left
      else
        earned = @coins_mine_amount
        @coins_mine_amount = 0
      end

      earned
    end

    def to_hash
      {
        income: @income,
        capacity: @capacity,
        amount: @coins_mine_amount
      }
    end

    def save!

    end

  end
end