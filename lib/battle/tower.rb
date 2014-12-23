require "lib/battle/base_entity"

module Battle
  class Tower < BaseEntity

    HEALTH_POINTS = 400

    attr_reader :blockable_by

    def build_entity
      @prototype = {
        health_points: HEALTH_POINTS
      }

      @health_points = HEALTH_POINTS
      @blockable_by = 99999
      @position = 0.05
    end

    def sync_data
      @force_sync = false
      [@uid, @health_points]
    end

    def to_a
      [@uid, @health_points, @position]
    end

    def processable?(d_time)
      false
    end

  end
end
