require 'thread_safe'
require 'lib/worker'

module Reactor
  module React
    def attach_to_worker
      @worker = Reactor.worker
    end

    # async method: :sync, payload: payload, after: 20
    def async(method, payload)
      @worker << [self, method, payload]
    end

    def after(method, payload, after_interval)
      EventMachine::next_tick do
        EventMachine::Timer.new(after_interval) { @worker << [self, method, payload] }
      end
    end
  end

  class << self

    attr_accessor :num_threads

    def configure
      yield self
    end

    def link(name, actor)
      @linked_actors ||= ThreadSafe::Hash.new

      unless @linked_actors[name].nil?
        @linked_actors[name].kill!
      end

      @linked_actors[name] = actor
    end

    def [](name)
      @linked_actors[name]
    end

    def worker
      @workers_cycled.next
    end

    def run!
      workers = ThreadSafe::Array.new(@num_threads.to_i, Worker.new)
      @workers_cycled = workers.cycle
    end
  end
end
