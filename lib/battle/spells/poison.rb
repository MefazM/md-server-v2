module Battle
  class Poison < AbstractSpell

    def initialize(opponents, caster_uid, target_uid, options)
      super

      build_instant!

      send_view
    end

    def affect!
      affected_units = []
      @target.select(*@target_bounds) do |unit|
        affected_units << unit.uid
        unit.affect(:poison, OverTimeSpell.new(:decrease_health_points, @prototype[:slot_a], @prototype[:time], @prototype[:slot_b]))
      end

      send_spell_icons(affected_units)
    end

    def self.friendly_targets?
      false
    end

  end
end
