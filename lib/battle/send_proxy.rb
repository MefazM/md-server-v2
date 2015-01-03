module Battle
  class SendProxy

    def initialize(sender_uid)
        @sender_uid = sender_uid
    end

    def method_missing(method, *args, &block)

      actor = Reactor.actor(@sender_uid)
      if actor && actor.alive?
        if args.empty?

          actor.method(method).call
        else

          actor.method(method).call(args[0])
        end
      end
    end

  end
end
