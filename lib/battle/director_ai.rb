require 'lib/battle/director'

module Battle
  class DirectorAi < Director

    def broadcast
      yield(@opponents.values[0].proxy)
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
