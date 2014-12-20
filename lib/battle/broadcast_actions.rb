module Battle
  class BroadcastActions

    def initialize(*players_uids)
      @recipients = players_uids
    end

    def method_missing(method, *args, &block)
      @recipients.each do |uid|
        actor = Reactor.actor(uid)
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
end
