require 'thread_safe'
require 'json'


class Overlord

  class << self

    attr_accessor :num_threads

    def configure
      yield self
    end

    def observe name, actor
      @actors[name] = actor
    end

    def not_exists? name
      @actors[name].nil?
    end

    def push_request data
      @requests_queue << data
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

              actor = @actors[request[0]]
              if actor
                actor.act request[1], request[2]
              end

            else
              sleep 0.1
            end
          }
        }
      end
    end

    private

    def pop_request

    end

  end
end