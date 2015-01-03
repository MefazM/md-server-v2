module Battle
  class Curse < AbstractSpell

    def initialize(player, target, owner_uid, broadcast)
      super

      @prototype = Storage::GameData.spell_data(:z_fire)

      target_bounds!(@prototype[:area])
      build_instant!
    end

    def affect!
      affected_units = []

      @player.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        value = unit.opt_value(:attack_power, @prototype[:slot_a])
        unit.affect(:curse, EffectSwitchSpell.new(:attack_power, value, @prototype[:time], true))
      end

      @broadcast.send_spell_icons([:z_fire, @prototype[:spellbook_timing], affected_units])
    end

    def self.friendly_targets?
      false
    end

  end
end
