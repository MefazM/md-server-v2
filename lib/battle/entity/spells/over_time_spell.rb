module Battle
  class OverTimeSpell
    def initialize(attr_name, value, time, num_charges)
      @attr_name = attr_name
      @value = value
      @time = time
      @num_charges = num_charges
      @charges_count = num_charges

      @finish_at = time + Time.now.to_f
    end

    def reset!
      @charges_count = @num_charges
    end

    def ready?(time)
      if @finish_at < time
        @finish_at = @time + Time.now.to_f

        return true
      end

      false
    end

    def complited?
      @charges_count < 1
    end

    def mutate
      yield(@attr_name, @value)
    end

  end
end
