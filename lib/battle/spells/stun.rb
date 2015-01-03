module Battle
  class Stun < AbstractSpell

    def initialize(player, target, owner_uid, broadcast)
      super

      @prototype = Storage::GameData.spell_data(:rect_water)

      target_bounds!(@prototype[:area])
      build_instant!
    end

    def affect!
      affected_units = []
      @player.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        unit.affect(:stun, StunSpell.new(@prototype[:time]))
      end

      @broadcast.send_spell_icons([:rect_water, @prototype[:spellbook_timing], affected_units])
    end

    def self.friendly_targets?
      false
    end

  end
end
