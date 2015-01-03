module Battle
  class AbstractSpell

    attr_reader :owner_uid

    def initialize(source, target, data)
      @source, @target = source, target
      @position, @spell_name = data[:target], data[:name].to_sym

      @complited = false

      @prototype = Storage::GameData.spell_data(@spell_name)

      @target_bounds = calculate_target_bounds
    end

    def calculate_target_bounds
      target = self.class.friendly_targets? ? @position : 1.0 - @position

      [target - @prototype[:area] * 0.5, target + @prototype[:area] * 0.5]
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
      raise 'Not implemented!'
    end

    def finalize_spell!

      achieve! if achievementable?

      @source = nil
      @target = nil

      @complited = true
    end

    def complited?
      @complited
    end

    def achievementable?
      false
    end

    def achieve!
      raise 'Not implemented!'
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

    def send_view
      [@source, @target].each do |opponent|

        opponent.proxy.send_spell_cast([@spell_name, @position, opponent.uid])
      end
    end

    def send_spell_icons(affected_units)
      [@source, @target].each do |opponent|

        opponent.proxy.send_spell_icons([@spell_name, @prototype[:spellbook_timing], affected_units])
      end
    end

    def self.friendly_targets?
      true
    end
  end
end
