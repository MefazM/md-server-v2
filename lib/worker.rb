class Worker
  def initialize
    @queue = Queue.new
    @thread = Thread.new do

      loop {
        begin

          actor, method, payload = @queue.deq

          next unless actor || actor.alive?

          m = actor.method(method)

          payload ? m.call(payload) : m.call

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
