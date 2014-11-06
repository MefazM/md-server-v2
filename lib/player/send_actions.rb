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
        buildings: @buildings.export,
        units: {
          # restore unit production queue on client
          queue: {},
          ready: {},
        }
      }])
    end
    #TODO: move earned calculation to client
    def sync_coins(earned = nil)
      send_data([Send::GOLD_STORAGE_CAPACITY, {
        coins_storage: @coins_storage.to_hash,
        coins_mine: @coins_mine.to_hash,
        earned: earned
      }])
    end

    def sync_mana
      send_data([Send::MANA_SYNC, {
        mana_storage: @mana_storage.to_hash,
      }])
    end

    def sync_score
      send_data([Send::SCORE_SYNC, {
        score: @score.to_hash
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

    def start_game_scene(scene_name)
      send_data([Send::START_GAME_SCENE, {
        name: scene_name
      }])
    end

    def send_new_unit_task(unit_data)
      send_data([Send::PUSH_UNIT_CONSTRUCTION_TASK, {
        uid: unit_data[:uid],
        time: unit_data[:production_time],
        group: unit_data[:depends_on_building_uid]
      }])
    end

    def send_unit_task_ready(unit_data)
      send_data([Send::POP_UNIT_CONSTRUCTION_TASK, {
        uid: unit_data[:uid],
        group: unit_data[:depends_on_building_uid]
      }])
    end

  end
end
