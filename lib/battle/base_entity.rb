#!!!!!проверять цель до перемещения

# require "lib/battle/unit_spells_effect"

module Battle
  class BaseEntity
    # include UnitSpellsEffect

    # Unit states
    MOVE = 1
    DEAD = 3
    ATTACK_MELEE = 4
    ATTACK_RANGE = 5
    IDLE = 42
    #
    NO_TARGET = -1
    MAX_POSITION = 0.9

    attr_accessor :uid, :position, :name, #:status,
                  :movement_speed, :force_sync, :range_attack_power,
                  :melee_attack_power,  :health_points, :path_id

    attr_reader :prototype, :body_width, :target


    attr_reader :target, :position, :prototype, :body_width, :name

    def initialize(unit_uid, path_id = nil, position = 0.0)
      @name = unit_uid.to_sym
      @uid = SecureRandom.hex(5)
      # additional params
      @status = MOVE
      @position = position
      @force_sync = true
      @target = nil
      @affected_spells = {}
      @path_id = path_id
      @body_width = 1.0 - 0.015
      @time_penalty = -1

      build_entity

      # # initialization unit by prototype
      # @unit_prototype = Storage::GameData.unit(@name)
      # @range_attack_power = attack_power(:range_attack)
      # @melee_attack_power = attack_power(:melee_attack)
      # @health_points = @unit_prototype[:health_points]
      # @movement_speed = @unit_prototype[:movement_speed]
    end

    def force_sync!
      @force_sync = true
    end

    def at_same_path?(path_id)
      @path_id == path_id
    end

    def has_no_target?
      unless @target.nil?
        @target = nil if @target.position + @position > 1.0
      end

      # Does this realy need?
      unless @target.nil? || @target.at_same_path?(@path_id)
        @target = nil
      end

      @target.nil? || @target.dead?
    end

    def dead?
      @health_points < 0.0
    end

    def low_hp?(scale)
      @health_points.to_f < @prototype[:health_points].to_f * scale
    end

    def sync_data
      [@uid, @health_points, @status]
    end

    def decrease_health_points(value)
      puts("VIOLATE HP!! #{value}") if value < 0.0
      @health_points -= value
      force_sync!
    end

    def increase_health_points(value)
      @health_points = [@unit_prototype[:health_points], @health_points + value].min
      force_sync!
    end

    def set_target(target)
      unless target.nil?

        @target = target

        if @path_id != target.path_id
          @path_id = target.path_id
          force_sync!
        end
      end
    end

    def update(iteration_delta)
      if @force_sync
        @force_sync = false
        return true

      end

      false
    end

    private

    def set_status(value)
      force_sync! if @status != value
      @status = value
    end

    def build_entity
      @prototype = {
        health_points: 100
      }

      @health_points = 100
    end

  end
end