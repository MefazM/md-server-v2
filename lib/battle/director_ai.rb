require 'lib/battle/director'

module Battle
  class DirectorAi < Director


    def initialize(opponent_1, opponent_2)
      TheLogger.info("Initialize new battle...")

      @uid = ['battle', SecureRandom.hex(5)].join('_')

      @broadcast = BroadcastActions.new(opponent_1[:uid])

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

      TheLogger.info("Initialize battle AI on client...")

      @broadcast.send_create_new_battle({
        ids[0] => @opponents[ids[0]].battle_data,
        ids[1] => @opponents[ids[1]].battle_data
      })
    end

    def set_opponent_ready(player_uid)
      # Dont let start already started BD.
      return if @status != :pending
      TheLogger.info "Opponent ID = #{player_uid} is ready to battle."
      @opponents[player_uid].ready!

      start!
    end

  end
end
