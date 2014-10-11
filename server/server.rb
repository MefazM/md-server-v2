require 'rubygems'
require 'eventmachine'
require 'lib/logger'
require 'server/connection_handler'


module Server
  class << self

    attr_accessor :ip, :port, :connections
    attr_reader :logger

    def configure
      yield self

      @connections = ThreadSafe::Cache.new
    end

    def dispatch!
      TheLogger.info "*** Start Magic Server 'v#{VERSION}' on #{ip}:#{@port} ***"

      EventMachine::run {
        EventMachine::start_server(@ip, @port, ConnectionHandler) do |conn|
          push_connection conn
          conn
        end
      }
    end

    def send_data data, conn_uid
      EventMachine::next_tick {
        @connections[conn_uid.to_sym].send_data data
      }
    end

    private

    def push_connection conn
      @connections[conn.uid] = conn
    end

  end
end
