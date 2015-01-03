module Battle
  class Haste < AbstractSpell

    def initialize(player, target, owner_uid, broadcast)
      super

      @prototype = Storage::GameData.spell_data(:arrow_air)

      target_bounds!(@prototype[:area])
      build_instant!
    end

    def affect!
      affected_units = []
      @player.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        value = unit.opt_value(:movement_speed, @prototype[:slot_a])
        unit.affect(:haste, EffectSwitchSpell.new(:movement_speed, value, @prototype[:time]))
      end

      @broadcast.send_spell_icons([:arrow_air, @prototype[:spellbook_timing], affected_units])
    end

  end
end