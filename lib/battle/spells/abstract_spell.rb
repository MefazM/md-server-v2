module Battle
  class AbstractSpell

    attr_reader :owner_uid

    def initialize(player, target, owner_uid, broadcast)
      @player = player
      @target = target
      @owner_uid = owner_uid
      @broadcast = broadcast

      @complited = false
    end

    def process
      state = @stack[0] || :empty

      case state
      # Affect already allocated targets
      when :affect
        affect!
        @stack.delete_at(0)
      # Wait for spell life time expires
      when :wait
        @stack.delete_at(0) if (Time.now.to_f - @create_at) > @time_offset
      # Wait for delay between spell charges expire
      when :wait_charge
        if (Time.now.to_f - @charge_time) > @time_offset
          @charge_time = Time.now.to_f
          @stack.delete_at(0)
        end
      # Spell is ready if task stack is empty
      when :empty
        finalize_spell!
      end
    end

    def affect!
      puts('PIU!!!!!')
    end

    def target_bounds!(area)
      @target_bounds = [@target - area * 0.5, @target + area * 0.5]
    end

    def finalize_spell!
      @player = nil
      @complited = true
      @broadcast = nil
    end

    def complited?
      @complited
    end

    def achievementable?
      false
    end

    def build_instant!
      @stack = [:affect]
    end

    def build_delayed!(offset)
      @time_offset = offset
      @create_at = Time.now.to_f

      @stack = [:wait, :affect]
    end

    def build_over_time!(time, num_charges)
      @time_offset = time
      @charge_time = Time.now.to_f

      @stack = [:affect, :wait_charge] * num_charges
    end

    def self.friendly_targets?
      true
    end
  end
end
