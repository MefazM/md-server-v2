module Battle
  class Thunder < AbstractSpell

    def initialize(player, target, owner_uid, broadcast)
      super

      @prototype = Storage::GameData.spell_data(:z_air)

      target_bounds!(@prototype[:area])
      build_over_time!(@prototype[:time], @prototype[:slot_a])
    end

    def affect!
      @player.select(*@target_bounds) do |unit|

        unit.decrease_health_points(@prototype[:slot_b])
      end
    end

    def self.friendly_targets?
      false
    end

  end
end
