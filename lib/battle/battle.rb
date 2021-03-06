require 'lib/battle/opponent'

require 'lib/battle/director'
require 'lib/battle/director_ai'
require 'lib/battle/director_tutorial'

module Battle
  module React

    def attach_to_battle(battle)
      @battle_director = battle
    end

    def battle_snapshot
      units = @units.export[:units]
      units[:crusader] = 9999999

      {
        uid: uid,
        units: units,
        level: @score.current_level,
        username: @username
      }
    end

    def start_battle
      Battle.set_opponent_ready(uid)
    end
  end

  class << self

    @@battles = ThreadSafe::Cache.new

    def create_battle(opponent_1_uid, opponent_2_uid)
      opponents = [opponent_1_uid, opponent_2_uid].map do |uid|
        Reactor.actor(uid).battle_snapshot
      end

      director = Director.new(*opponents)

      @@battles[opponent_1_uid] = director
      @@battles[opponent_2_uid] = director
    end

    def create_ai_battle(player_data, ai_data)
      @@battles[player_data[:uid]] = DirectorAi.new(player_data, ai_data)
    end

    def create_tutorial_battle(player_uid)
      @@battles[player_uid] = DirectorTutorial.new(player_uid)
    end

    def [](player_uid)
      if @@battles[player_uid].nil?
        TheLogger.error("Can't find battle for player #{player_uid}")
        return nil
      end

      @@battles[player_uid]
    end

    def unlink(player_uid)
      @@battles.delete(player_uid)
    end

    def exists?(player_uid)
      @@battles.key?(player_uid)
    end

    def destroy_battle!(player_uid)
      @@battles[player_uid].destroy!
    end

    def call_custom_action(uid, action)
      @@battles[uid].custom(action)
    end

    def method_missing(method, *args, &block)
      @@battles[args[0]].method(method).call(*args) if @@battles[args[0]]
    end

  end
end
