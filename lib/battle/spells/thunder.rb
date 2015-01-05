module Battle
  class Thunder < AbstractSpell

    def initialize(opponents, caster_uid, target_uid, options)
      super

      @prototype = Storage::GameData.spell_data(:z_air)

      build_over_time!(@prototype[:time], @prototype[:slot_a])

      send_view
    end

    def affect!
      @target.select(*@target_bounds) do |unit|

        unit.decrease_health_points(@prototype[:slot_b])
      end
    end

    def self.friendly_targets?
      false
    end

  end
end
