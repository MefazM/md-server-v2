module Battle
  class Heal < AbstractSpell

    def initialize(opponents, caster_uid, target_uid, options)
      super

      build_instant!

      send_view
    end

    def affect!
      affected_units = []
      @target.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        unit.increase_health_points(@prototype[:slot_a])
      end

      send_spell_icons(affected_units)
    end

  end
end
