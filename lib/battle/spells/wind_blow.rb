module Battle
  class WindBlow < AbstractSpell

    def initialize(opponents, caster_uid, target_uid, options)
      super

      build_instant!
    end

    def affect!
      affected_units = []
      @target.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        unit.push_back(@prototype[:slot_a])
      end

      send_spell_icons(affected_units)
    end

    def self.friendly_targets?
      false
    end

  end
end
