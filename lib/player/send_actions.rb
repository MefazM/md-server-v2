require 'server/actions_headers'

module Player
  module SendActions

    def send_notification(notification_uid, payload = nil)
      data = [notification_uid]
      data << payload unless payload.nil?

      send_all_data([Send::NOTIFICATION, data])
    end

    def send_authorised
      send_all_data([Send::AUTHORISED, {
        player: {
          uid: uid,
          email: @email,
          username: @username
        },
        buildings: @buildings.export
      }])
    end
    #TODO: move earned calculation to client
    def sync_coins(earned = nil)
      send_all_data([Send::GOLD_STORAGE_CAPACITY, {
        coins_storage: @coins_storage.to_hash,
        coins_mine: @coins_mine.to_hash,
        earned: earned
      }])
    end

    def sync_mana
      send_all_data([Send::MANA_SYNC, {
        mana_storage: @mana_storage.to_hash,
      }])
    end

    def sync_score
      send_all_data([Send::SCORE_SYNC, {
        score: @score.to_hash
      }])
    end

    def send_game_data
      send_all_data([Send::GAME_DATA, Storage::GameData.initialization_data])
    end

    def send_pong
      send_all_data([Send::PONG, Time.now.to_i])
    end

    def sync_building(building, ready)
      send_all_data([Send::BUILDING_SYNC, {
        uid: building[:uid],
        level: building[:level],
        ready: ready,
        construction_time: building[:production_time]
      }])
    end

    def sync_units
      send_all_data([Send::SYNC_UNITS, {
        units: @units.export,
        server_time: Time.now.to_i
      }])
    end

    def start_game_scene(scene_name)
      send_all_data([Send::START_GAME_SCENE, {
        name: scene_name
      }])
    end

    def send_lobby_data(players, ai)
      send_all_data([Send::UPDATE_LOBBY_DATA, {
        players: players,
        ai: ai,
        offset: 0
      }])
    end

    def send_invite_to_battle(data)
      send_all_data([Send::INVITE_TO_BATTLE, data])
    end

    def send_cancel_invite_to_battle
      send_all_data([Send::CANCEL_INVITE])
    end

    def send_create_new_battle(data)
      send_all_data([Send::CREATE_NEW_BATTLE, data])
    end

    def send_cast_spell(data)
      send_all_data([Send::CAST_SPELL, data])
    end

    def send_spawn_unit(data)
      send_all_data([Send::SPAWN_UNIT, data])
    end

    def send_start_battle
      send_all_data([Send::START_BATTLE])
    end

    def send_finish_battle(data)
      send_all_data([Send::FINISH_BATTLE, data])
    end

    def send_sync_battle(data)
      send_all_data([Send::SYNC_BATTLE, data])
    end

    def send_spell_cast(data)
      send_all_data([Send::CAST_SPELL, data])
    end

    def send_spell_icons(data)
      send_all_data([Send::SPELL_ICONS, data])
    end

  end
end
