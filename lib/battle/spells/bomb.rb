module Battle
  class Bomb < AbstractSpell

    def initialize(source, target, position)
      super

      build_delayed!(@prototype[:time])

      send_view
    end

    def affect!
      @target.select(*@target_bounds) do |unit|

        unit.decrease_health_points(@prototype[:slot_a])
      end
    end

    def self.friendly_targets?
      false
    end

  end
end
