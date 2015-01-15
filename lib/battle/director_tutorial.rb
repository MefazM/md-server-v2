require 'lib/battle/director_ai'

module Battle
  class DirectorTutorial < Director

    def initialize(player_uid)
      ai_data = {
        uid: :tutorial_ai,
        units:  {slinger:  15, crusader:  99999999},
        level: 0,
        username: 'Tutorial Ai'
      }

      player_data = {
        uid: player_uid,
        units:  {spearman:  5, crusader:  99999999},
        level: 0,
        username: 'Player'
      }

      @player_uid = player_uid

      super(player_data, ai_data, :tutorial)
    end

    def broadcast
      yield(@opponents[@player_uid].proxy)
    end

    def set_opponent_ready(player_uid)
      # Dont let start already started BD.
      return if @status != :pending
      TheLogger.info "Opponent ID = #{player_uid} is ready to battle."
      @opponents[player_uid].ready!

      start!
    end

    def custom(action_name)
      case action_name
      when 'spawn_peasants'
        @opponents.each_key do |player_id|
          unit = spawn_unit(player_id, 'crusader')
          unit.indestructible = true
          unit.blockable_by = 999

          type = @player_uid == player_id ? :tutor_friendly : :tutor_enemy

          @opponents[@player_uid].proxy.send_spell_icons([type, 10000, [unit.uid]])
        end

      when 'spawn_archers'
        spawn_unit(:tutorial_ai, 'slinger')

      when 'freeze_game'
        @opponents.each_value do |opponent|
          opponent.pathway.each{|unit| unit.set_freeze(true) }
        end

      when 'unfreeze_game'
        @opponents.each_value do |opponent|
          opponent.pathway.each{|unit| unit.set_freeze(false) }
        end

      when 'disable_indestructible'
        @opponents.each_value{|opponent| opponent.pathway.first.indestructible = false }

      when 'cast_spell'
        slingers = @opponents[:tutorial_ai].pathway.select{|unit| unit.name == :slinger}.map{|unit| unit.position}

        @spells_factory.create(@player_uid, {
          target: 1.0 - (slingers.reduce(:+).to_f / slingers.size),
          name: :circle_fire
        }) unless slingers.empty?

      end
    end

    def spawn_default_units
    end

    def unlink_battle
      Battle.unlink(@player_uid)
    end

  end
end
