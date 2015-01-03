module Battle
  class EffectSwitchSpell
    def initialize(attr_name, value, time, inverted = false)
      @attr_name = attr_name
      @value = value
      @time = time
      @inverted = inverted

      @finish_at = time + Time.now.to_f

      if inverted
        @affect_method = "decrease_#{@attr_name}"
        @dispell_method = "increase_#{@attr_name}"
      else
        @affect_method = "increase_#{@attr_name}"
        @dispell_method = "decrease_#{@attr_name}"
      end

      @complited = false
    end

    def reset!
      @finish_at = @time + Time.now.to_f
    end

    def ready?(time)
      @complited = @finish_at < time
    end

    def complited?
      @complited
    end

    def mutate
      yield(@complited ? @dispell_method : @affect_method, @value)
    end

  end
end
