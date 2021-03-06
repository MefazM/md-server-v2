module Battle
  class Stun < AbstractSpell

    def initialize(opponents, caster_uid, target_uid, options)
      super

      build_instant!
    end

    def affect!
      affected_units = []
      @target.select(*@target_bounds) do |unit|

        affected_units << unit.uid
        unit.affect(:stun, StunSpell.new(@prototype[:time]))
      end

      send_spell_icons(affected_units)
    end

    def self.friendly_targets?
      false
    end

  end
end
