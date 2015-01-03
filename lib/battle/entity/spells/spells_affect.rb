module Battle
  module SpellsAffect

    def opt_value(name, percentage = nil)
      percentage.nil? ? instance_variable_get("@#{name}") : @prototype[name] * percentage
    end

    def affect(uid, spell_handler)
      if @affected_spells.has_key?(uid)

        @affected_spells[uid].reset!
      else

        spell_handler.mutate {|attr_name, value| send(attr_name, value)}

        @affected_spells[uid] = spell_handler
      end
    end

    def process_spells
      current_time = Time.now.to_f

      @affected_spells.delete_if do |uid, spell|
        if spell.ready?(current_time)

          spell.mutate {|meth, val| method(meth).call(val)}
        end

        spell.complited?
      end
    end

  end
end
