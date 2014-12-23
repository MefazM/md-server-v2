require "lib/battle/base_entity"

module Battle
  class Unit < BaseEntity

    attr_reader :blockable_by, :distance_attack

    def build_entity
      # initialization unit by prototype
      @prototype = Storage::GameData.unit(@name)

      @attack_power = attack_power
      @health_points = @prototype[:health_points]
      @movement_speed = @prototype[:movement_speed]
      @blockable_by = @prototype[:blockable_by]
      @distance_attack = @prototype[:distance_attack]
    end

    def sync_data
      @force_sync = false

      data = [@uid, @health_points, @state, @position.round(3)]

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

    private

    def attack_power
      rand(@prototype[:attack_power_min]..@prototype[:attack_power_max])
    end
  end
end