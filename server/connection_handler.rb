require 'securerandom'
require 'json'
require 'lib/player'

module Server
  class ConnectionHandler < EM::Connection

    include Player

    MESSAGE_START_TOKEN = '__JSON__START__'
    MESSAGE_END_TOKEN = '__JSON__END__'

    def initialize
      @connection_uid = [:sock, SecureRandom.hex(5)].join.to_sym
      @buffer = ''
      Reactor.observe(@connection_uid, self)
    end

    def post_init
      @alive = true
    end

    def unbind
      @alive = false
    end

    def connection_completed
      @alive = false
    end

    def send_data(data)
      EventMachine::next_tick {
        super ['__JSON__START__', data.to_json, '__JSON__END__'].join if @alive
      }
    end

    def receive_data(data)
      @buffer += data
      loop do
        str_start = @buffer.index MESSAGE_START_TOKEN
        str_end = @buffer.index MESSAGE_END_TOKEN
        if str_start || str_end
          message = @buffer.slice!(str_start .. str_end + 12)
          json = message.slice(str_start + 15 .. str_end - 1)

          action, payload = *JSON.parse( json, symbolize_names: true)
          perform(action, payload)
        else
          break
        end
      end

    end

  end
end
