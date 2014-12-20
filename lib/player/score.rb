require 'lib/player/redis_mapper'

module Player
  class Score

    include RedisMapper

    def initialize(player_id)
      @player_id = player_id
      @redis_key = ['players', @player_id].join(':')

      restore_from_redis(@redis_key, { score: 0 }){ |v| v.to_i }

      current_level!
    end

    def current_level!
      level = 0
      Storage::GameData.player_levels.each{|score| level += 1 if @score > score[:level_at] }

      @level = level
    end

    def current_level
      @level
    end

    def to_a
      to_hash.values
    end

    def to_hash
      level_at = Storage::GameData.next_level_at @level
      prev_level = [0, @level].min
      prev_level_at = if @level == 0
        0
      else
        prev_level_at = Storage::GameData.next_level_at prev_level
      end

      {
        score: @score,#4
        level_at: level_at - prev_level_at,
        level: @level,
        level_score: @score - prev_level_at
      }
    end

    def save!
      save_to_redis(@redis_key, [:score])
    end

    def increase(value)
      @score += value
    end

  end
end