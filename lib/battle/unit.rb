#!!!!!проверять цель до перемещения
# require "lib/battle/unit_spells_effect"

require "lib/battle/base_entity"

module Battle
  class Unit < BaseEntity
    # include UnitSpellsEffect

    def build_entity
      # initialization unit by prototype
      @prototype = Storage::GameData.unit(@name)

      @attack_power = attack_power
      @health_points = @prototype[:health_points]
      @movement_speed = @prototype[:movement_speed]
    end

    def sync_data
      data = [@uid, @health_points, @status, @position.round(3), @path_id]

      # case @status
      # when ATTACK_RANGE
      #   data << @target.position
      # when MOVE
      #   data << @movement_speed / @prototype[:movement_speed]
      # end

      data
    end

    def in_attack_range?(target)
      distantion = target.position + @position

      ((distantion + @prototype[:attack_range]) > target.body_width) && (distantion < 1.0)
    end

    def attack!
      @target.decrease_health_points(@attack_power)
      @time_penalty = @prototype[:attack_speed]

      set_status(ATTACK)

      force_sync!
    end

    def can_attack?
      @time_penalty < 0.0 && !has_no_target?
    end

    def can_move?
      @time_penalty < 0.0
    end

    def update(iteration_delta)

      @time_penalty -= iteration_delta if @time_penalty > 0.0

      if can_attack?
        if in_attack_range?(@target)
          if @target.has_no_target?
            @target.set_target(self)
          elsif not @target.target == self

            position_to_target = 1.0 - (@target.position + @target.target.position)
            position_to_this_attaker = 1.0 - (@target.position + @position)

            if position_to_target > 0.07 &&  position_to_target > position_to_this_attaker
              @target.set_target(self)
            end

          end

          attack!
        end
      end

      if can_move?
        @position += iteration_delta * @movement_speed
        set_status(MOVE)
      end

      set_status(DEAD) if @health_points < 0.0

      if @force_sync
        @force_sync = false
        return true

      end

      false
    end

    private

    def attack_power
      rand(@prototype[:attack_power_min]..@prototype[:attack_power_max])
    end
  end
end