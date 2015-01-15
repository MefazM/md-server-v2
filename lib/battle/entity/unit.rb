require "lib/battle/entity/base_entity"

module Battle
  class Unit < BaseEntity

    attr_reader :distance_attack

    attr_accessor :attack_power, :health_points, :movement_speed, :indestructible, :blockable_by

    def build_entity
      # initialization unit by prototype
      @prototype = Storage::GameData.unit(@name)

      @attack_power = @prototype[:attack_power]
      @health_points = @prototype[:health_points]
      @movement_speed = @prototype[:movement_speed]
      @blockable_by = @prototype[:blockable_by]
      @distance_attack = @prototype[:distance_attack]

      @indestructible = false
    end

    def speed_scale
      if @state == MOVE

        @movement_speed / @prototype[:movement_speed]
      elsif @state == ATTACK

        # @attack_speed / @prototype[:attack_speed]
        1.0
      else
        1.0
      end
    end

    def sync_data
      @force_sync = false

      data = [@uid, @health_points, @state, @position.round(3), speed_scale]

      data << @last_attacked_uid unless @last_attacked_uid.nil?

      data
    end

    def attack_distantion
      @prototype[:attack_range]
    end

    def in_attack_range?(target)
      distantion = target.position + @position

      distantion >= (1.0 - @prototype[:attack_range]) && distantion <= 1.0
    end

    def attack(target)
      target.decrease_health_points(@attack_power)
      @time_penalty = @prototype[:attack_speed]

      @last_attacked_uid = target.uid

      set_state(ATTACK)
    end

    def can_move?
      true
    end

    def increase_movement_speed(value)
      @movement_speed += value
      force_sync!
    end

    def decrease_movement_speed(value)
      @movement_speed -= value
      force_sync!
    end

    def increase_attack_power(value)
      @attack_power += value
    end

    def decrease_attack_power(value)
      @attack_power = 0.0 if (@attack_power -= value) < 0.0
    end

    def decrease_health_points(value)
      unless @indestructible
        puts("VIOLATE HP!! #{value}") if value < 0.0
        force_sync!
        @health_points -= value
      end

      @health_points
    end

    def increase_health_points(value)
      force_sync!
      @health_points = [@prototype[:health_points], @health_points + value].min
    end

    def push_back(value)
      @position -= value
      force_sync!
    end

  end
end