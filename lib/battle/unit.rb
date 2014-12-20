#!!!!!проверять цель до перемещения
# require "lib/battle/unit_spells_effect"

require "lib/battle/base_entity"

module Battle
  class Unit < BaseEntity
    # include UnitSpellsEffect

    def build_entity
      # initialization unit by prototype
      @prototype = Storage::GameData.unit(@name)

      @range_attack_power = attack_power(:range_attack)
      @melee_attack_power = attack_power(:melee_attack)

      @health_points = @prototype[:health_points]
      @movement_speed = @prototype[:movement_speed]
    end

    def sync_data
      data = [@uid, @health_points, @status, @position.round(3), @path_id]

      case @status
      when ATTACK_RANGE
        data << @target.position
      when MOVE
        data << @movement_speed / @prototype[:movement_speed]
      end

      data
    end

    def in_attack_range?(target, attack_type)
      # If unit has not such kind of attack
      return false unless @prototype[attack_type]
      # Calculate distance
      attack_range = @prototype[attack_type][:range]
      distantion = target.position + @position

      return ((distantion + attack_range) > target.body_width) && (distantion < 1.0)
    end

    def attack(attack_type)
      case attack_type
      when :melee_attack
        @target.decrease_health_points(@melee_attack_power)
        @time_penalty = @prototype[:melee_attack][:speed]

        set_status(ATTACK_MELEE)
      when :range_attack
        @target.decrease_health_points(@range_attack_power)
        @time_penalty = @prototype[:range_attack][:speed]

        set_status(ATTACK_RANGE)
        force_sync!
      end
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
        [:melee_attack, :range_attack].each do |type|
          if in_attack_range?(@target, type)

            if @target.has_no_target?
              @target.set_target(self)
            elsif not @target.target == self

              position_to_target = 1.0 - (@target.position + @target.target.position)
              position_to_this_attaker = 1.0 - (@target.position + @position)

              if position_to_target > 0.07 &&  position_to_target > position_to_this_attaker
                @target.set_target(self)
              end

            end

            attack(type)

            break
          end

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

    def attack_power(attack_type)
      return nil if @prototype[attack_type].nil?
      min = @prototype[attack_type][:power_min]
      max = @prototype[attack_type][:power_max]

      rand(min..max)
    end
  end
end