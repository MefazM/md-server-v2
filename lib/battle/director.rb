require 'lib/battle/opponent'
require 'lib/battle/calculate_battle_results'

require 'lib/battle/spells/spells_factory'

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
        ids[0] => @opponents[ids[1]],
        ids[1] => @opponents[ids[0]]
      }

      @status = :pending

      TheLogger.info("Initialize battle on clients...")

      battle_data = {
        ids[0] => @opponents[ids[0]].battle_data,
        ids[1] => @opponents[ids[1]].battle_data
      }

      broadcast do |proxy|
        proxy.send_create_new_battle({
          battle_data: battle_data
        })
      end

      @spells_factory = SpellsFactory.new(@opponents)

      ObjectSpace.define_finalizer(self, proc {|id| puts "Director removed! #{id}" })
    end

    def broadcast
      @opponents.each_value {|opponent| yield(opponent.proxy)}
    end

    def restore_opponent(player_uid)
      player = @opponents[player_uid]

      ids = @opponents.keys
      player.proxy.send_create_new_battle({
        battle_data: {
          ids[0] => @opponents[ids[0]].battle_data,
          ids[1] => @opponents[ids[1]].battle_data
        }
      })

      @opponents.each do |player_uid, opponent|
        opponent.pathway.each do |unit|
          unit.force_sync!
          player.proxy.send_spawn_unit(unit.uid, unit.name, player_uid)
        end
      end

      player.proxy.send_start_battle
    end

    def cast_spell(player_uid, data)
      @spells_factory.create(player_uid, data)
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
      start! if @opponents.values.all? {|opponent| opponent.ready?}
    end

    # ==================================================
    # Update:
    # 1. Calculating units moverment, damage and states.
    # 2. Calculating outer effects (user spells, ...)
    # 3. Default units spawn.
    def update(prev_iteration_time)
      return unless @status == :in_progress

      if @next_wave_time < Time.now.to_i
        @next_wave_time = Time.now.to_i + DEFAULT_UNITS_SPAWN_TIME
        spawn_default_units
      end

      @spells_factory.update

      current_time = Time.now.to_f
      # World update
      iteration_delta = current_time - prev_iteration_time

      sync_data = []

      @opponents.each do |player_id, player|

        sync_data += player.update(@opponents_inverted[player_id], iteration_delta)

        if player.lose?
          finish_battle(player_id)
          break
        end
      end

      unless sync_data.empty?
        broadcast {|proxy| proxy.send_sync_battle(sync_data)}
      end

      after(:update, current_time, 0.1) if @status == :in_progress
    end

    # Additional units spawning.
    def spawn_unit(player_id, unit_name)
      unit = @opponents[player_id].add_unit_to_pool(unit_name.to_sym)
      broadcast {|proxy| proxy.send_spawn_unit(unit.uid, unit_name, player_id)} unless unit.nil?
      unit
    end
    # Destroy battle director
    def destroy!
      @spells_factory.clear!
      @status = :finished

      unlink_battle
    end

    def alive?
      @status != :finished
    end

    private
    # Start the battle.
    def start!
      TheLogger.info("Battle Director ##{@uid} started!")
      @status = :in_progress
      @start_time = Time.now.to_i
      @next_wave_time = Time.now.to_i + DEFAULT_UNITS_SPAWN_TIME

      broadcast {|proxy| proxy.send_start_battle}

      after(:update, Time.now.to_f, 0.2)

      spawn_default_units
    end

    def spawn_default_units
      @opponents.each_key{|player_id|
        # spawn_unit(player_id, ['adept', 'scout', 'spearman', 'crusader'].sample)
        spawn_unit(player_id, 'crusader')
      }
    end

    def finish_battle(loser_id)
      TheLogger.info("Battle finished, player (#{loser_id} - lose.)")

      destroy!

      ids = @opponents.keys
      data = {
        ids[0] => calculate_battle_reward(ids[0], ids[0] != loser_id),
        ids[1] => calculate_battle_reward(ids[1], ids[1] != loser_id)
      }

      broadcast {|proxy| proxy.sync_after_battle(data)}

      @opponents.each do |uid, opponent|
        # opponent.destroy!
        Lobby.unfreeze!(uid)
      end
    end

    def unlink_battle
      @opponents.keys.each {|uid| Battle.unlink(uid)}
    end

  end
end
