module Battle
  class PoisonCloud < AbstractSpell

    # slot_a - num charge
    # slot_b - hp decrease
    # slot_c - slow value

    def initialize(player, target, owner_uid, broadcast)
      super

      @prototype = Storage::GameData.spell_data(:z_water)

      target_bounds!(@prototype[:area])
      build_over_time!(@prototype[:time], @prototype[:slot_a])
    end

    def affect!

      @player.select(*@target_bounds) do |unit|
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
