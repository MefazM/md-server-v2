module Battle
  class Haste < AbstractSpell

    def initialize(opponents, caster_uid, target_uid, options)
      super

      build_instant!
    end

    def affect!
      affected_units = []
      @target.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        value = unit.opt_value(:movement_speed, @prototype[:slot_a])
        unit.affect(:haste, EffectSwitchSpell.new(:movement_speed, value, @prototype[:time]))
      end

      send_spell_icons(affected_units)
    end

  end
end