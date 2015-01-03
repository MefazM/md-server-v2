#!!!!!проверять цель до перемещения
require "lib/battle/entity/spells/spells_affect"


module Battle
  class BaseEntity

    include SpellsAffect

    MOVE = 1
    DEAD = 3
    ATTACK = 6
    IDLE = 42

    MAX_POSITION = 0.9

    attr_reader :uid, :name, :position

    def initialize(unit_uid, position = 0.0)
      @name = unit_uid.to_sym
      @uid = SecureRandom.hex(5)
      # additional params
      @state = MOVE
      @position = position
      @force_sync = true

      @affected_spells = {}

      @time_penalty = 0.0

      build_entity

      @frozen = false
    end

    def force_sync!
      @force_sync = true
    end

    def dead?
      @health_points <= 0.0
    end

    def low_hp?(scale)
      @health_points.to_f < @prototype[:health_points].to_f * scale
    end

    def sync_data
      @force_sync = false
      [@uid, @health_points, @state]
    end

    def can_move?
      false
    end

    def outdated?
      @force_sync
    end

    def move(d_time)
      @position += d_time * @movement_speed
      set_state(MOVE)
    end

    def processable?(d_time)
      process_spells

      if @health_points <= 0.0
        set_state(DEAD)

        return false
      end

      return false if (@time_penalty -= d_time) > 0.0

      return false if @frozen

      true
    end

    def set_freeze(value)
      @frozen = value
      set_state(IDLE) if value
    end

    private

    def set_state(value)
      force_sync! if @state != value
      @state = value
    end

    def build_entity
      @prototype = {
        health_points: 100
      }

      @health_points = 100
    end

  end
end