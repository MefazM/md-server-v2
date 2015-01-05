# spells mountable to units
require "lib/battle/entity/spells/over_time_spell"
require "lib/battle/entity/spells/effect_switch_spell"
require "lib/battle/entity/spells/stun_spell"

#
require 'lib/battle/spells/abstract_spell.rb'
require 'lib/battle/spells/haste.rb'
require 'lib/battle/spells/slow.rb'
require 'lib/battle/spells/fireball.rb'
require 'lib/battle/spells/heal.rb'
require 'lib/battle/spells/poison.rb'
require 'lib/battle/spells/regeneration.rb'
require 'lib/battle/spells/wind_blow.rb'
require 'lib/battle/spells/stun.rb'
require 'lib/battle/spells/bomb.rb'
require 'lib/battle/spells/thunder.rb'
require 'lib/battle/spells/curse.rb'
require 'lib/battle/spells/bless.rb'
require 'lib/battle/spells/poison_cloud.rb'

module Battle

  class SpellsFactory
    # Ugly mapping
    @@spells = {
      circle_fire: Fireball,
      circle_earth: Heal,
      circle_water: Bomb,

      arrow_air: Haste,
      arrow_water: Slow,
      arrow_earth: Regeneration,
      arrow_fire: Bless,

      z_water: PoisonCloud,
      z_air: Thunder,
      z_fire: Curse,
      z_earth: Poison,

      rect_air: WindBlow,
      rect_water: Stun,
    }

    def initialize(opponents)
      @opponents = opponents
      @spells = []

      ids = @opponents.keys
      @opponents_inverted = {
        ids[0] => @opponents[ids[1]],
        ids[1] => @opponents[ids[0]]
      }
    end

    def create(caster_uid, options)

      handler = @@spells[options[:name].to_sym]

      target_uid = handler.friendly_targets? ? caster_uid : @opponents_inverted[caster_uid].uid

      @spells << handler.new(@opponents, caster_uid, target_uid, options)
    end

    def update
      @spells.delete_if do |spell|

        spell.process

        spell.complited?
      end
    end

    def clear!
      @opponents_inverted = nil
      @opponents = nil
      @spells = nil
    end

  end
end
