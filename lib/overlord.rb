require 'thread_safe'
require 'json'

class Overlord
  class << self
    attr_accessor :num_threads

    def configure
      yield self
    end

    def observe(name, actor)
      @actors[name] = actor
    end

    def not_observed?(name)
      @actors[name].nil?
    end

    def push_action(data)
      @requests_queue << data
    end

    def [](name)
      actor = @actors[name]
      raise "Attempt to call a dead actor - #{name}" if actor.nil?

      actor
    end

    def run!
      @requests_queue = ThreadSafe::Array.new
      @actors = ThreadSafe::Cache.new

      @threads = []

      @num_threads.to_i.times do
        @threads << Thread.new {
          loop {
            request = @requests_queue.pop
            if request
              begin
                name, action, payload = request

                @actors[name].method(action).call(payload)

              rescue Exception => e
                TheLogger.error <<-MSG
                  Can't call actor by name= '#{name}', action: '#{action}'
                  #{e}
                  #{e.backtrace.join('\n')}
                MSG
              end

            else
              #TODO: use blocking queue instead
              sleep 0.1
            end
          }
        }
      end
    end
  end
end