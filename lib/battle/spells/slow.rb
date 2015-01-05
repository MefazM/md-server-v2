module Battle
  class Slow < AbstractSpell

    def initialize(opponents, caster_uid, target_uid, options)
      super

      build_instant!

      send_view
    end

    def affect!
      @target.select(*@target_bounds) do |unit|

        value = unit.opt_value(:movement_speed, @prototype[:slot_a])
        unit.affect(:slow, EffectSwitchSpell.new(:movement_speed, value, @prototype[:time], true))
      end
    end

    def self.friendly_targets?
      false
    end

  end
end