require 'thread_safe'
require 'json'


require 'lib/worker'

module Reactor
  # module Actor
  #   def observe(name, actor)
  #     @queue_id = Reactor.observe(name, actor)
  #   end
  #   def perform(data)
  #   end
  #   def after(interval, data)
  #   end
  # end
  class << self

    attr_accessor :num_threads

    def configure
      yield self
    end

    def less_loaded
      @workers_loading_map.rindex(@workers_loading_map.min)
    end

    def observe(name, actor)

      queue_id = less_loaded
      @workers_loading_map[queue_id] += 1

      @actors[name] = {
        actor: actor,
        queue_id: queue_id
      }
    end

    def kill_actor(name)
      actor = @actors[name]
      unless actor.nil?
        actor[:actor].kill!
        queue_id = actor[:queue_id]

        @workers_loading_map[queue_id] -= 1

        @actors.delete(name)
      end

    end

    def not_observed?(name)
      @actors[name].nil?
    end

    def [](name)
      actor = @actors[name][:actor]
      raise "Attempt to call a dead actor - #{name}" if actor.nil?

      actor
    end

    def <<(data)
      queue_id = @actors[data[0]][:queue_id]
      @workers[queue_id] << data
    end

    def perform_after(interval, data)
      queue_id = @actors[data[0]][:queue_id]

      EventMachine::next_tick do
        EventMachine::Timer.new(interval) do
          @workers[queue_id] << data
        end
      end
    end

    # def perform_every(interval, data)
    #   EventMachine::next_tick {
    #     EventMachine::PeriodicTimer.new(interval) { @queue << data }
    #   }
    # end

    def run!
      @actors = ThreadSafe::Cache.new
      @workers = ThreadSafe::Array.new

      @workers_loading_map = ThreadSafe::Array.new(@num_threads.to_i, 0)

      @num_threads.to_i.times do |i|

        @workers << Worker.new do |name, action, payload|
          # binding.pry

          actor = @actors[name]


          @actors[name][:actor].method(action).call(payload) if actor
        end
      end

      # @queue = Queue.new
      # @actors = ThreadSafe::Cache.new
      # @threads = []

      # @num_threads.to_i.times do
      #   @threads << Thread.new do
      #     loop do
      #       # begin
      #         name, action, payload = @queue.deq
      #         actor = @actors[name]
      #         if actor
      #           @actors[name].method(action).call(payload)
      #         end

      #       # rescue Exception => e
      #       #   TheLogger.error <<-MSG
      #       #     Can't call actor by name= '#{name}', action: '#{action}'
      #       #     #{e}
      #       #     #{e.backtrace.join('\n')}
      #       #   MSG
      #       # end
      #     end
      #   end

      # end
    end

  end
end
