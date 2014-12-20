require "lib/battle/base_entity"

module Battle
  class Tower < BaseEntity

    HEALTH_POINTS = 400

    attr_reader :engaged_routes

    def build_entity
      @body_width = 1.0 - 0.1
      @prototype = {
        health_points: HEALTH_POINTS
      }

      @health_points = HEALTH_POINTS
      @position = 0.05

      @engaged_routes = [2,3,4,5,6]
    end

    def path_id
      @engaged_routes.sample
    end

    def at_same_path?(path_id)
      @engaged_routes.include? path_id
    end

    def sync_data
      [@uid, @health_points]
    end

    def to_a
      [@uid, @health_points, @position]
    end

  end
end
