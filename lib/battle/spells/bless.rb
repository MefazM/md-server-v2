module Battle
  class Bless < AbstractSpell

    # slot_a

    def initialize(source, target, position)
      super

      build_instant!
    end

    def affect!
      affected_units = []
      @target.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        value = unit.opt_value(:attack_power, @prototype[:slot_a])
        unit.affect(:bless, EffectSwitchSpell.new(:attack_power, value, @prototype[:time]))
      end

      send_spell_icons(affected_units)
    end

  end
end
