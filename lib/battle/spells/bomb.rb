module Battle
  class Bomb < AbstractSpell

    def initialize(player, target, owner_uid, broadcast)
      super

      @prototype = Storage::GameData.spell_data(:circle_water)

      target_bounds!(@prototype[:area])
      build_delayed!(@prototype[:time])
    end

    def affect!
      @player.select(*@target_bounds) do |unit|

        unit.decrease_health_points(@prototype[:slot_a])
      end
    end

    def self.friendly_targets?
      false
    end

  end
end
