module Battle
  class Bless < AbstractSpell

    # slot_a

    def initialize(player, target, owner_uid, broadcast)
      super

      @prototype = Storage::GameData.spell_data(:arrow_fire)

      target_bounds!(@prototype[:area])
      build_instant!
    end

    def affect!
      affected_units = []
      @player.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        value = unit.opt_value(:attack_power, @prototype[:slot_a])
        unit.affect(:bless, EffectSwitchSpell.new(:attack_power, value, @prototype[:time]))
      end

      @broadcast.send_spell_icons([:arrow_fire, @prototype[:spellbook_timing], affected_units])
    end

  end
end
