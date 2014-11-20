require 'securerandom'
require 'lib/player'
require 'msgpack'

module Server
  class ConnectionHandler < EM::Connection
    include Reactor::React
    include Player

    MSG_START_TOKEN = '__SMSG__'
    MSG_END_TOKEN = '__EMSG__'

    def initialize
      @buffer = ''
      # attach_to_reactor
      # @async = AsyncCall.new
      attach_to_worker
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

    def alive?
      @alive
    end

    def send_data(data)
      EventMachine::next_tick {
        super [MSG_START_TOKEN, MessagePack.pack(data), MSG_END_TOKEN].join if @alive
      }
    end

    def receive_data(data)
      @buffer += data
      loop do
        str_start = @buffer.index(MSG_START_TOKEN)
        str_end = @buffer.index(MSG_END_TOKEN)
        if str_start || str_end
          str = @buffer.slice!(str_start .. str_end + 7)
          msg = str.slice(str_start + 8 .. str_end - 1)

          action, payload = MessagePack.unpack( msg, :symbolize_keys => true )
          perform(action, payload)
        else
          break
        end
      end

    end

  end
end
