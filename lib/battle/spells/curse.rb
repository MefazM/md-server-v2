module Battle
  class Curse < AbstractSpell

    def initialize(opponents, caster_uid, target_uid, options)
      super

      build_instant!
    end

    def affect!
      affected_units = []

      @target.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        value = unit.opt_value(:attack_power, @prototype[:slot_a])
        unit.affect(:curse, EffectSwitchSpell.new(:attack_power, value, @prototype[:time], true))
      end

      send_spell_icons(affected_units)
    end

    def self.friendly_targets?
      false
    end

  end
end
