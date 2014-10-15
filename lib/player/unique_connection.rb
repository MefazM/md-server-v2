require 'thread_safe'

module Player
  module UniqueConnection
    @@map = ThreadSafe::Cache.new

    def make_uniq!
      unless @@map[@player_id].nil?
        TheLogger.warn "Player already connected! Drop previous connection..."
        Overlord[@@map[@player_id]].kill!
      end

      @@map[@player_id] = @uid
    end
  end
end