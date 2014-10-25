require 'thread_safe'
require 'json'

module Overlord
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

    def <<(data)
      @queue << data
    end

    def perform_after(interval, data)
      EventMachine::Timer.new(interval) { @queue << data }
    end

    def perform_every(interval, data)
      EventMachine::PeriodicTimer.new(interval) { @queue << data }
    end

    def [](name)
      actor = @actors[name]
      raise "Attempt to call a dead actor - #{name}" if actor.nil?

      actor
    end

    def run!
      @queue = Queue.new
      @actors = ThreadSafe::Cache.new
      @threads = []

      @num_threads.to_i.times do
        @threads << Thread.new do
          loop do
            # begin
            name, action, payload = @queue.deq
            @actors[name].method(action).call(payload)

            # rescue Exception => e
            #   TheLogger.error <<-MSG
            #     Can't call actor by name= '#{name}', action: '#{action}'
            #     #{e}
            #     #{e.backtrace.join('\n')}
            #   MSG
            # end
          end
        end

      end
    end

  end
end
