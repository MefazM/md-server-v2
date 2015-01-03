module Battle
  class Regeneration < AbstractSpell

    def initialize(source, target, position)
      super

      build_instant!
    end

    def affect!
      affected_units = []
      @target.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        unit.affect(:regeneration, OverTimeSpell.new(:increase_health_points, @prototype[:slot_a], @prototype[:time], @prototype[:slot_b]))
      end

      send_spell_icons(affected_units)
    end

  end
end
