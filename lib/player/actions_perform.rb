require 'lib/overlord'
require 'lib/logger'

module Player
  module ActionsPerform

    def self.included(base)
      base.send :extend, ClassMethods
    end

    def self.map_action(*params)
      request, handler = *params

      @@registered_actions ||= {}
      @@registered_actions[request] = { authorized: false }.merge(handler)
    end

    module ClassMethods
      def map_action(request, handler)
        ActionsPerform.map_action request.to_sym, handler
      end
    end

    def perform(action, payload)
      handler = @@registered_actions[action.to_sym]

      if handler.nil?
        TheLogger.error "Can't perform action: [#{action}], handler not found!"
        return
      end

      if handler[:authorized] and not_authorized?
        TheLogger.error "Can't perform unauthorized action: [#{action}]!"
        return
      end

      Overlord.push_action([@uid, handler[:as], payload])
    end
  end
end