require 'lib/logger'

module Server
  module RequestPerform
    def self.included(base)
      base.send :extend, ClassMethods
    end

    def self.map_request *params
      request, handler = *params

      handler.merge! autorized: false

      @@registered_actions ||= {}
      @@registered_actions[request] = handler
    end

    module ClassMethods
      def map_request request, handler
        Server::RequestPerform.map_request request.to_sym, handler
      end
    end

    def perform(request, payload)
      handler = @@registered_actions[request.to_sym]

      if handler.nil?
        TheLogger.error "Can't perform request: [#{request}], handler not found!"
        return
      end

      if handler[:autorized] and not autorized?
        TheLogger.error "Can't perform unautorized request: [#{request}]!"
        return
      end
      send(handler[:as], payload)

      rescue Exception => e
        TheLogger.error <<-MSG
          Can't perform handler: [#{handler}] for request: [#{request}]
          #{e}
          #{e.backtrace.join('\n')}
        MSG
    end
  end
end
