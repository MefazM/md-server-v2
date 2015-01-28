require 'timers'
class Worker
  def initialize
    @queue = Queue.new
    @timers = Timers::Group.new
    @reactor_thread = Thread.new do
      loop do
        begin
          unless @queue.empty?
            actor, method, payload = @queue.deq(false)
            next unless actor || actor.alive?
            payload.nil? ? actor.method(method).call : actor.method(method).call(payload)
          end

          unless @timers.wait_interval.nil? || @timers.wait_interval >= 0.0
            @timers.fire
          end

        rescue Exception => e
          TheLogger.error <<-MSG
            Can't call actor '#{actor.class.to_s}', action: '#{method}'
            #{e}
            #{e.backtrace.join("\n")}
          MSG
        end
      end
    end

    Thread.current[:timers] = @timers
    Thread.current[:worker] = self
  end

  def after(period, actor, method, payload)
    @timers.after(period) { @queue << [actor, method, payload] }
  end

  def <<(data)
    @queue << data
  end
end
