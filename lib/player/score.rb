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
        :score => @score,#4
        :level_at => level_at - prev_level_at,
        :level => @level,
        :level_score => @score - prev_level_at
      }
    end

    def save!
      save_to_redis(@redis_key, [:score])
    end

    # def update_score(data)
    #   opponent_id = determine_opponent! data
    #   is_winner = @id == data[:winner_id]
    #   spells_score, spells_statistics = calculate_spells_score
    #   units_score, units_killed = calculate_killed_units_score(data)
    #   score_modifier = calculate_score_modifier(data, opponent_id)
    #   fast_battle_score = calculate_time_bonus(data)
    #   achievement_score = fast_battle_score + spells_score
    #   static_level_reward = calculate_static_level_reward

    #   battle_score = if is_winner
    #     static_level_reward + units_score + achievement_score
    #   else
    #     units_score + achievement_score
    #   end

    #   battle_score *= score_modifier * Storage::GameData.game_rate

    #   @score += battle_score

    #   stat = {
    #     battle_time: data[:battle_time],
    #     units_killed: units_killed,
    #     units_killed_score: units_score,
    #     is_winner: is_winner,
    #     static_win: static_level_reward,
    #     opponent_name: data[opponent_id][:username],
    #     modifier: score_modifier,
    #     spells: spells_statistics,
    #     score: battle_score.to_i,
    #     score_sum: @score,
    #     coins: calculate_coins(battle_score),
    #     fast_battle_score: fast_battle_score
    #   }

    #   put_coins_to_storage(stat[:coins])!
    #   calculate_current_level!
    # end

    # def determine_opponent!(battle_results)
    #   if @id == battle_results[:winner_id]
    #     battle_results[:loser_id]
    #   elsif @id == battle_results[:loser_id]
    #     battle_results[:winner_id]
    #   end
    # end

    # def calculate_coins(coins)
    #   (coins * Storage::GameData.score_to_coins_modifier).to_i
    # end

    # def calculate_score_modifier(battle_results, opponent_id)
    #   opponent_level = battle_results[opponent_id][:level]
    #   opponent_level = opponent_level.zero? ? 1 : opponent_level

    #   player_level = @level.zero? ? 1 : @level

    #   opponent_level / player_level
    # end

    # def calculate_spells_score(battle_results)
    #   score = 0
    #   spells_grouped = {}
    #   spells_statistics = []

    #   battle_results[@id][:spells].each { |uid| spells_grouped[uid] = spells_grouped[uid].to_i + 1 }
    #   # calculate score for each spell
    #   spells_grouped.each do |uid, times|

    #     spell_score = Storage::GameData.battle_score_settings[uid][:score_price] * times

    #     unless spell_score.nil?
    #       spells_statistics << {
    #         :name => uid,
    #         :count => times,
    #         :score => spell_score
    #       }

    #       score += spell_score
    #     end
    #   end

    #   [score, spells_statistics]
    # end

    # def calculate_killed_units_score(battle_results)
    #   units_score = 0
    #   units_killed = 0

    #   battle_results[@id][:units].each do |uid, unit_data|
    #     units_score += Storage::GameData.battle_score_settings[uid][:score_price] * unit_data[:lost]
    #     units_killed += unit_data[:lost]
    #   end

    #   [units_score, units_killed]
    # end

    # def calculate_time_bonus(battle_results)
    #   if battle_results[:battle_time] > Storage::GameData.battle_score_settings[:fast_battle][:time_period]
    #     fast_battle_score = Storage::GameData.battle_score_settings[:fast_battle][:score_price]

    #     return fast_battle_score
    #   end

    #   0
    # end

    # def calculate_static_level_reward(is_winner)
    #   is_winner ? Storage::GameData.battle_reward @level : 0
    # end

    # def score_sync_data
    #   level_at = Storage::GameData.next_level_at @level
    #   prev_level = [0, @level].min
    #   prev_level_at = if @level == 0
    #     0
    #   else
    #     prev_level_at = Storage::GameData.next_level_at prev_level
    #   end

    #   {
    #     :score => @score,#4
    #     :level_at => level_at - prev_level_at,
    #     :level => @level,
    #     :level_score => @score - prev_level_at
    #   }
    # end

    # def calculate_current_level
    #   @level = 0
    #   Storage::GameData.player_levels.each{|score| @level += 1 if @score > score[:level_at] }
    # end

    # def calculate_current_level!
    #   calculate_current_level
    #   send_score_sync
    # end

    # def send_score_sync
    #   # sync_data = score_sync_data.values.unshift :syncScore
    #   # send_custom_event([:syncScore, @score, next_level_at, @level])
    #   # send_custom_event sync_data
    # end

  end
end