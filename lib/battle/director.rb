require 'lib/battle/opponent'
require 'lib/battle/broadcast_actions'
require 'lib/battle/calculate_battle_results'

module Battle
  class Director

    DEFAULT_UNITS_SPAWN_TIME = 1.0

    include Reactor::React
    include CalculateBattleResults

    def initialize(opponent_1, opponent_2)
      TheLogger.info("Initialize new battle...")

      @uid = ['battle', SecureRandom.hex(5)].join('_')

      attach_to_worker

      @opponents = {
        opponent_1[:uid] => Opponent.new(opponent_1),
        opponent_2[:uid] => Opponent.new(opponent_2)
      }

      ids = @opponents.keys
      @opponents_inverted = {
        ids[0] => ids[1],
        ids[1] => ids[0]
      }

      @status = :pending

      @broadcast = BroadcastActions.new(opponent_1[:uid], opponent_2[:uid])

      TheLogger.info("Initialize battle on clients...")

      @broadcast.send_create_new_battle({
        ids[0] => @opponents[ids[0]].battle_data,
        ids[1] => @opponents[ids[1]].battle_data
      })
    end

    def cast_spell(player_uid, target, spell_data)
      # spell = SpellFactory.create(spell_data, player_uid)
      # return nil if spell.nil?

      # # spell.channel = @channel

      # area = spell_data[:area]
      # life_time = spell.life_time * 1000

      # # publish(@channel, [:send_spell_cast, spell_data[:uid], life_time, target, player_uid, area])

      # if spell.friendly_targets?
      #   spell.set_target(target, @opponents[player_uid].path_ways)
      # else
      #   target = 1.0 - target

      #   opponent_uid = @opponents_inverted[player_uid]
      #   spell.set_target(target, @opponents[opponent_uid].path_ways)
      # end

      # @spells << spell
    end
    # After initialization battle on clients.
    # Battle starts after all opponents are ready.
    def set_opponent_ready(player_uid)
      # Dont let start already started BD.
      return if @status != :pending
      TheLogger.info "Opponent ID = #{player_uid} is ready to battle."
      @opponents[player_uid].ready!
      # Autostart battle
      # Battle ready to start, if each opponent is ready.
      all_ready = @opponents.values.all? {|opponent| opponent.ready?}
      if all_ready
        start!
      end
    end

    # ==================================================
    # Update:
    # 1. Calculating units moverment, damage and states.
    # 2. Calculating outer effects (user spells, ...)
    # 3. Default units spawn.
    def update(prev_iteration_time)

      if @next_wave_time < Time.now.to_i
        @next_wave_time = Time.now.to_i + DEFAULT_UNITS_SPAWN_TIME
        spawn_default_units
      end

      current_time = Time.now.to_f
      # World update
      iteration_delta = current_time - prev_iteration_time
      # update_spells(current_time, iteration_delta)
      sync_data = []

      @opponents.each do |player_id, player|
        opponent_uid = @opponents_inverted[player_id]
        opponent = @opponents[opponent_uid]

        sync_data += player.update(opponent, iteration_delta)

        if player.lose?
          finish_battle(player_id)
          break
        end
      end

      @broadcast.send_sync_battle(sync_data) unless sync_data.empty?

      after(:update, current_time, 0.1) if @status == :in_progress
    end
    # Update spells
    def update_spells(current_time, iteration_delta)
      # @spells.each do |spell|

      #   spell.update(current_time, iteration_delta)

      #   if spell.completed

      #     if spell.achievementable?
      #       @opponents[spell.player_id].track_spell_statistics spell.uid

      #       notificate_player_achievement!(spell.player_id, spell.uid, spell.killed_units)
      #     end

      #     @spells.delete spell
      #   end

      # end
    end
    # Additional units spawning.
    def spawn_unit(player_id, unit_name)
      unit = @opponents[player_id].add_unit_to_pool(unit_name.to_sym)

      @broadcast.send_spawn_unit(unit) unless unit.nil?
    end
    # Destroy battle director
    def destroy
      # @opponents.each_value { |opponent| opponent.destroy! }
    end

    private
    # Start the battle.
    def start!
      TheLogger.info("Battle Director ##{@uid} started!")
      @status = :in_progress
      @start_time = Time.now.to_i
      @next_wave_time = Time.now.to_i + DEFAULT_UNITS_SPAWN_TIME
      @broadcast.send_start_battle

      after(:update, Time.now.to_f, 0.2)

      spawn_default_units
    end

    def spawn_default_units
      @opponents.each_key{|player_id|
        spawn_unit(player_id, ['adept', 'scout', 'spearman', 'crusader'].sample)
      }
    end

    def finish_battle(loser_id)
      TheLogger.info("Battle finished, player (#{loser_id} - lose.)")

      @status = :finished

      ids = @opponents.keys
      data = {
        battle_time: Time.now.to_i - @start_time,
        winner_id: @opponents_inverted[loser_id],
        loser_id: loser_id,
        ids[0] => calculate_battle_reward(ids[0], ids[0] != loser_id),
        ids[1] => calculate_battle_reward(ids[1], ids[1] != loser_id)
      }

      @broadcast.sync_after_battle(data)
      @opponents_inverted.each{|uid| Lobby.unfreeze!(uid)}
    end



  end
end
