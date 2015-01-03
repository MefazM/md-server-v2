module Battle
  class Heal < AbstractSpell

    def initialize(player, target, owner_uid, broadcast)
      super

      @prototype = Storage::GameData.spell_data(:circle_earth)

      target_bounds!(@prototype[:area])
      build_instant!
    end

    def affect!
      affected_units = []
      @player.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        unit.increase_health_points(@prototype[:slot_a])
      end

      @broadcast.send_spell_icons([:circle_earth, @prototype[:spellbook_timing], affected_units])
    end

  end
end
