module Battle
  class Fireball < AbstractSpell

    def initialize(opponents, caster_uid, target_uid, options)
      super

      @units_to_kill = Storage::GameData.battle_score_settings[:circle_fire][:units_to_kill]
      @killed_units = 0

      build_delayed!(@prototype[:time])

      send_view
    end

    def achieve!
      @source.proxy.send_notification(@spell_name, @killed_units)
      @source.track_spell_statistics(@spell_name)
    end

    def affect!
      @target.select(*@target_bounds) do |unit|

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
