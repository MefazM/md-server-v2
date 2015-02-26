module Battle
  module CalculateBattleResults

    def calculate_battle_reward(player_id, is_winner)
      statistics = @opponents[player_id].statistics

      spells_score, spells_statistics = calculate_spells_score(statistics)
      units_score, units_killed = calculate_killed_units_score(statistics)
      score_modifier = calculate_score_modifier(statistics, player_id)

      battle_time = Time.now.to_i - @start_time
      fast_battle_score = fast_battle_time_bonus(battle_time)

      achievement_score = fast_battle_score + spells_score
      static_level_reward = is_winner ? calculate_static_level_reward(statistics) : 0

      battle_score = if is_winner
        static_level_reward + units_score + achievement_score
      else
        units_score + achievement_score
      end

      battle_score *= score_modifier * Storage::GameData.game_rate

      {
        battle_time: battle_time,
        units_killed: units_killed,
        units_killed_score: units_score,
        is_winner: is_winner,
        static_win: static_level_reward,
        opponent_name: @opponents_inverted[player_id].username,
        modifier: score_modifier,
        spells: spells_statistics,
        score: battle_score.to_i,
        coins: calculate_coins(battle_score),
        fast_battle_score: fast_battle_score,
        lost_units: statistics[:units][:lost],
        level: statistics[:level],
      }
    end

    def determine_opponent!(battle_results)
      if @player_id == battle_results[:winner_id]
        battle_results[:loser_id]
      else
        battle_results[:winner_id]
      end
    end

    def calculate_coins(battle_score)
      (battle_score * Storage::GameData.score_to_coins_modifier).to_i
    end

    def calculate_score_modifier(statistics, player_id)
      opponent = @opponents_inverted[player_id]
      opponent_level = opponent.statistics[:level]
      opponent_level = opponent_level.zero? ? 1 : opponent_level

      player_level = statistics[:level].zero? ? 1 : statistics[:level]

      opponent_level.to_f / player_level.to_f
    end

    def calculate_spells_score(statistics)
      score = 0
      spells_grouped = {}
      spells_statistics = []

      statistics[:spells].each { |uid| spells_grouped[uid] = spells_grouped[uid].to_i + 1 }
      # calculate score for each spell
      spells_grouped.each do |uid, times|

        spell_score = Storage::GameData.battle_score_settings[uid][:score_price] * times

        unless spell_score.nil?
          spells_statistics << {
            :name => uid,
            :count => times,
            :score => spell_score
          }

          score += spell_score
        end
      end

      [score, spells_statistics]
    end

    def calculate_killed_units_score(statistics)
      units_score = 0
      units_killed = 0

      statistics[:units][:lost].each do |uid, count|
        units_score += Storage::GameData.battle_score_settings[uid][:score_price] * count
        units_killed += count
      end

      [units_score, units_killed]
    end

    def fast_battle_time_bonus(battle_time)
      if battle_time > Storage::GameData.battle_score_settings[:fast_battle][:time_period]
        fast_battle_score = Storage::GameData.battle_score_settings[:fast_battle][:score_price]

        return fast_battle_score
      end

      0
    end

    def calculate_static_level_reward(statistics)
      Storage::GameData.battle_reward(statistics[:level])
    end
  end
end
