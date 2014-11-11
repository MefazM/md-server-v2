require 'thread_safe'

module Player
  module UniqueConnection
    @@map = ThreadSafe::Cache.new

    def make_uniq!
      old_connection_name = @@map[@player_id]

      unless old_connection_name.nil?
        TheLogger.warn("Player already connected! Drop previous connection...")
        Reactor.kill_actor(old_connection_name)
      end

      @@map[@player_id] = @connection_uid
    end

    def kill_all_players!

    end

  end
end