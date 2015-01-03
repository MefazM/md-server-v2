module Battle
  class StunSpell
    def initialize(time)
      @time = time
      @finish_at = time + Time.now.to_f

      @complited = false
    end

    def reset!
      @finish_at = @time + Time.now.to_f
    end

    def ready?(time)
      puts("#{@finish_at} #{time}")
      @complited = @finish_at < time
    end

    def complited?
      @complited
    end

    def mutate
      yield('set_freeze', !@complited)
    end

  end
end
