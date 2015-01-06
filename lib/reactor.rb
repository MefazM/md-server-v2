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

    def alive?
      true
    end
  end

  class << self

    attr_accessor :num_threads

    @@linked_actors = ThreadSafe::Hash.new

    def configure
      yield self
    end

    def link(actor)
      unless @@linked_actors[actor.uid].nil?
        TheLogger.info "Kill old actor #{actor.uid}"
        @@linked_actors[actor.uid].kill!
      end

      @@linked_actors[actor.uid] = actor
    end

    def actor(name)
      @@linked_actors[name]
    end

    def actors(names)
      @@linked_actors.values_at(*names)
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
