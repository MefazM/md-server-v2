module Battle
  class PoisonCloud < AbstractSpell

    # slot_a - num charge
    # slot_b - hp decrease
    # slot_c - slow value

    def initialize(opponents, caster_uid, target_uid, options)
      super

      build_over_time!(@prototype[:time], @prototype[:slot_a])

      send_view
    end

    def affect!
      @target.select(*@target_bounds) do |unit|
        unit.decrease_health_points(@prototype[:slot_b])

        value = unit.opt_value(:movement_speed, @prototype[:slot_c])
        unit.affect(:poison_cloud_slow, EffectSwitchSpell.new(:movement_speed, value, @prototype[:time], true))
      end
    end

    def self.friendly_targets?
      false
    end

  end
end
