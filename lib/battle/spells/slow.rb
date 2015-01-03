module Battle
  class Slow < AbstractSpell

    def initialize(player, target, owner_uid, broadcast)
      super

      @prototype = Storage::GameData.spell_data(:arrow_water)

      target_bounds!(@prototype[:area])
      build_instant!
    end

    def affect!
      @player.select(*@target_bounds) do |unit|

        value = unit.opt_value(:movement_speed, @prototype[:slot_a])
        unit.affect(:slow, EffectSwitchSpell.new(:movement_speed, value, @prototype[:time], true))
      end
    end

    def self.friendly_targets?
      false
    end

  end
end