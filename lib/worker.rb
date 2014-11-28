class Worker
  def initialize
    @queue = Queue.new
    @thread = Thread.new do

      loop {
        begin

          actor, method, payload = @queue.deq
          actor.method(method).call(payload) if actor && actor.alive?

        rescue Exception => e
          TheLogger.error <<-MSG
            Can't call actor by name= '#{actor.inspect}', action: '#{method}'
            #{e}
            #{e.backtrace.join("\n")}
          MSG
        end

      }
    end
  end

  def <<(data)
    @queue << data
  end
end
