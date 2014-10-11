require 'securerandom'
require 'json'
require 'actor/overlord'
require 'server/request_perform'

module Server
  class ConnectionHandler < EM::Connection
    include RequestPerform

    map_request :login, as: :process_login_action
    # map_request :player, as: :process_player_action
    map_request :new_battle, as: :process_lobby_action
    map_request :battle_start, as: :process_battle_action
    map_request :lobby_data, as: :process_lobby_action
    map_request :spawn_unit, as: :process_battle_action
    map_request :unit_production_task, as: :process_player_action
    map_request :spell_cast, as: :process_battle_action
    map_request :response_battle_invite, as: :process_lobby_action
    map_request :ping, as: :process_sytem_action
    map_request :building_production_task, as: :process_player_action
    map_request :do_harvesting, as: :process_player_action
    map_request :current_mine, as: :process_player_action
    map_request :reload_gd, as: :process_sytem_action

    attr_reader :uid

    MESSAGE_START_TOKEN = '__JSON__START__'
    MESSAGE_END_TOKEN = '__JSON__END__'

    def initialize
      @uid = [:sock, SecureRandom.hex(5)].join.to_sym
      @buffer = ''
      @auth_id = nil
    end

    def post_init
    end

    def unbind
    end

    def authorize! auth_id
      @auth_id = auth_id
    end

    def autorized?
      not @auth_id.nil?
    end

    # TODO: Kill connections if they push messages to dead actors

    def process_login_action payload
      Overlord.push_request([:login, payload, @uid])
    end

    def process_lobby_action payload

    end

    def process_battle_action payload

    end

    def process_player_action payload
      if autorized?
        Overlord.push_request([['player_', @auth_id].join.to_sym, payload, @uid])
      end
    end

    def process_sytem_action payload
      send_data ['pong', {counter: payload[:counter] + 1}]
    end

    def send_data data
      super ['__JSON__START__', data.to_json, '__JSON__END__'].join
    end

    def receive_data data
      @buffer += data

      loop {
        str_start = @buffer.index MESSAGE_START_TOKEN
        str_end = @buffer.index MESSAGE_END_TOKEN
        if str_start and str_end
          message = @buffer.slice!(str_start .. str_end + 12)
          json = message.slice(str_start + 15 .. str_end - 1)

          request, payload = *JSON.parse( json, symbolize_names: true)
          perform(request, payload)
        else
          break
        end
      }

    end
  end
end
