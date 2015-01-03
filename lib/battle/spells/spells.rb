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

  module Spells
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

    # def initialize(players, broadcast)
    #   @players = players
    #   @broadcast = broadcast
    #   @spells = []
    # end

    def self.[](spell_name)
      @@spells[spell_name.to_sym]
    end

    # def create(player_uid, data)

    #   handler = @@spells[data[:name].to_sym]

    #   if handler.nil?

    #     TheLogger.error("Can'p perform spell - #{data[:name]}!")
    #   else

    #     uid = handler.friendly_targets? ? player_uid : @opponents_inverted[player_uid]

    #     @spells << handler.new(@players[uid], @broadcast, data[:target], player_uid)
    #     # @broadcast.send_spell_cast([data[:name].to_sym, data[:target], player_uid])
    #   end
    # end

    # def process(d_time)
    #   @spells.delete_if do |spell|

    #     spell.process

    #     spell.complited?
    #   end
    # end

  end
end
