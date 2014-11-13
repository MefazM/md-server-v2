class Worker
  def initialize
    @queue = Queue.new
    @actors = ThreadSafe::Cache.new


    @thread = Thread.new do

      loop do

        name, action, payload = @queue.deq
        yield(name, action, payload)

      end

    end

  end

  def <<(data)
    @queue << data
  end

end