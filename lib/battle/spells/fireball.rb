module Battle
  class Fireball < AbstractSpell

    def initialize(player, target, owner_uid, broadcast)
      super

      @prototype = Storage::GameData.spell_data(:circle_fire)

      @units_to_kill = Storage::GameData.battle_score_settings[:circle_fire][:units_to_kill]
      @killed_units = 0

      target_bounds!(@prototype[:area])
      build_instant!
    end

    def affect!
      @player.select(*@target_bounds) do |unit|

        unit.decrease_health_points(@prototype[:slot_a].to_f)

        @killed_units += 1 if unit.dead?
      end
    end

    def achievementable?
      @killed_units >= @units_to_kill
    end

    def self.friendly_targets?
      false
    end

  end
end
