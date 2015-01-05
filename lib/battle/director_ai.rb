require 'lib/battle/director'

module Battle
  class DirectorAi < Director

    def initialize(opponent_1, opponent_2)
      @player_uid = opponent_1[:uid]
      @ai_uid = opponent_2[:uid]

      @ai_settings = opponent_2

      super
    end

    def broadcast
      yield(@opponents[@player_uid].proxy)
    end

    def set_opponent_ready(player_uid)
      # Dont let start already started BD.
      return if @status != :pending
      TheLogger.info "Opponent ID = #{player_uid} is ready to battle."
      @opponents[player_uid].ready!

      start!

      after(:ai_update, nil, @ai_settings[:activity_period])
    end

    AI_ACTIONS = [:ai_heal, :ai_buff, :ai_debuff, :ai_atk_spell, :ai_spawn_unit]

    def ai_update
      if @status == :in_progress

        method(AI_ACTIONS.sample).call
        after(:ai_update, nil, @ai_settings[:activity_period])
      end
    end

    ###### AI

    def ai_heal
      matched_path_way = @opponents[@ai_uid].units_at_front( 20 ) {|unit| unit.low_hp?(0.6)}

      if matched_path_way
        position, matches = matched_path_way

        return if matches < 1

        @spells_factory.create(@ai_uid, {
          target: position,
          name: @ai_settings[:heal].sample
        })
      end
    end

    def ai_buff
      matched_path_way = @opponents[@ai_uid].units_at_front

      unless matched_path_way.nil?
        position, matches = matched_path_way

        return if matches < 2

        @spells_factory.create(@ai_uid, {
          target: position,
          name: @ai_settings[:buff].sample
        })
      end
    end

    def ai_debuff
      matched_path_way = @opponents[@player_uid].units_at_front(20)

      unless matched_path_way.nil?
        position, matches = matched_path_way

        return if matches < 1

        @spells_factory.create(@ai_uid, {
          target: 1.0 - position,
          name: @ai_settings[:debuff].sample
        })
      end
    end

    def ai_atk_spell
      matched_path_way = @opponents[@player_uid].units_at_front(20)

      unless matched_path_way.nil?
        position, matches = matched_path_way

        return if matches < 1

        @spells_factory.create(@ai_uid, {
          target: 1.0 - position,
          name: @ai_settings[:atk_spell].sample.to_s
        })
      end
    end

    def ai_spawn_unit
      spawn_unit(@ai_uid, @ai_settings[:units].keys.sample)
    end

  end
end
