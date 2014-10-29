require 'server/actions_headers'

module Player
  module SendActions

    private

    def send_notification(notification_uid, payload = nil)
      message = [Send::NOTIFICATION, notification_uid]
      message << payload unless payload.nil?

      send_data(message)
    end

    def send_authorised
      send_data([Send::AUTHORISED, {
        player_data: {
          coins_storage: @coins_storage.to_hash,
          coins_mine: @coins_mine.to_hash,
          mana_storage: @mana_storage.to_hash,
          score: @score.to_hash,
          buildings: @buildings.export,
          units: {
            # restore unit production queue on client
            queue: {},
            ready: {},
          },
        },
        start_scene: :world
      }])
    end
    #TODO: move earned calculation to client
    def sync_coins(earned = 0)
      send_data([Send::GOLD_STORAGE_CAPACITY, {
        earned: earned,
        coins_storage: @coins_storage.to_hash,
        coins_mine: @coins_mine.to_hash,
      }])
    end

    def send_game_data
      send_data([Send::GAME_DATA, Storage::GameData.initialization_data])
    end

    def send_pong
      send_data([Send::PONG, Time.now.to_i])
    end

    def sync_building(building, ready)
      send_data([Send::BUILDING_SYNC, {
        uid: building[:uid],
        level: building[:level],
        ready: ready,
        construction_time: building[:production_time]
      }])
    end

  end
end
