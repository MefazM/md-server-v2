require 'lib/reactor'
require 'lib/logger'

module Player
  module RequestsDispatcher

    def self.included(base)
      base.send :extend, ClassMethods
    end

    def self.map_requests(*params)
      request, handler = *params

      @@registered_requests ||= {}
      @@registered_requests[request] = { authorized: false }.merge(handler)
    end

    module ClassMethods
      def map_requests(request, handler)
        RequestsDispatcher.map_requests request.to_sym, handler
      end
    end

    def perform(request, payload)
      handler = @@registered_requests[request.to_sym]

      if handler.nil?
        TheLogger.error "Can't perform request: [#{request}], handler not found!"
        return
      end

      if handler[:authorized] and not_authorized?
        TheLogger.error "Can't perform unauthorized request: [#{request}]!"
        return
      end

      async(handler[:as], payload)
    end
  end
end
