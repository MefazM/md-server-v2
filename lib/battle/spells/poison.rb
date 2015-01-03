module Battle
  class Poison < AbstractSpell

    def initialize(player, target, owner_uid, broadcast)
      super

      @prototype = Storage::GameData.spell_data(:z_earth)

      target_bounds!(@prototype[:area])
      build_instant!
    end

    def affect!
      affected_units = []
      @player.select(*@target_bounds) do |unit|
        affected_units << unit.uid
        unit.affect(:poison, OverTimeSpell.new(:decrease_health_points, @prototype[:slot_a], @prototype[:time], @prototype[:slot_b]))
      end

      @broadcast.send_spell_icons([:z_earth, @prototype[:spellbook_timing], affected_units])
    end

    def self.friendly_targets?
      false
    end

  end
end
