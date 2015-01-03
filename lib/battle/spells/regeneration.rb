module Battle
  class Regeneration < AbstractSpell

    def initialize(player, target, owner_uid, broadcast)
      super

      @prototype = Storage::GameData.spell_data(:arrow_earth)

      target_bounds!(@prototype[:area])
      build_instant!
    end

    def affect!
      affected_units = []
      @player.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        unit.affect(:regeneration, OverTimeSpell.new(:increase_health_points, @prototype[:slot_a], @prototype[:time], @prototype[:slot_b]))
      end

      @broadcast.send_spell_icons([:arrow_earth, @prototype[:spellbook_timing], affected_units])
    end

  end
end
