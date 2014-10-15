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
    end

    def dispatch!
      TheLogger.info "*** Start Magic Server 'v#{VERSION}' on #{ip}:#{@port} ***"

      EventMachine::run {
        EventMachine::start_server(@ip, @port, ConnectionHandler)
      }
    end

  end
end
