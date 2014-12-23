require 'lib/battle/tower'
require 'lib/battle/unit'

module Battle
  class Opponent

    attr_reader :username, :statistics, :tower, :pathway

    def initialize(data)
      @uid = data[:uid]
      @ready = false

      @tower = Tower.new(@uid)

      @pathway = [@tower]

      @username = data[:username]

      @statistics = {
        units: {
          available: data[:units],
          lost: {}
        },
        spells: [],
        level: data[:level]
      }

      @chached_targets = {}
    end

    def battle_data
      {
        uid: @uid,
        tower: @tower.to_a,
        units: @statistics[:units][:available]
      }
    end

    def units_at_front(segment_length = 15)
    #   positions = {}
    #   @path_ways.flatten.each do |unit|

    #     segment = ((unit.position / segment_length) * 100).to_i
    #     key = ['k', 'segment'].join

    #     positions[key] ||= {
    #       :count => 0,
    #       :pos => 0.0
    #     }

    #     if block_given?
    #       if yield(unit)
    #         positions[key][:count] += 1
    #         positions[key][:pos] += unit.position
    #       end
    #     else
    #       positions[key][:count] += 1
    #       positions[key][:pos] += unit.position
    #     end
    #   end

    #   matched, matches = positions.max_by{|_,u| u[:count]}

    #   return nil if matched.nil?

    #   avg_pos = matches[:pos] / matches[:count].to_f

    #   return avg_pos, matches[:count]
    end

    def track_spell_statistics(uid)
      @statistics[:spells] << uid
    end

    def lose?
      @tower.dead?
    end

    def sort_units!
      @pathway.sort_by! {|v| v.position}.reverse!
    end

    def get_target(attaker, opponent_units)
      opponent_units.find do |unit|
        if attaker.in_attack_range?(unit)

          count = @chached_targets.inject(0) do |c, (a, t)|
            c += (t == unit.uid ? 1 : 0)
          end

          count < unit.blockable_by
        else

          false
        end
      end
    end

    def update(opponent, d_time)
      opponent.sort_units!

      sync_data = []

      @pathway.each do |unit|

        if unit.processable?(d_time)
          target = get_target(unit, opponent.pathway)
          if target
            unit.attack(target)

            @chached_targets[unit.uid] = target.uid
          else
            unit.move(d_time) if unit.can_move?

            @chached_targets[unit.uid] = nil
          end
        end

        sync_data << unit.sync_data if unit.outdated?

        if unit.dead? && unit != @tower # do not track statistics for tower
          # Iterate lost unit counter
          @statistics[:units][:lost][unit.name] ||= 0
          @statistics[:units][:lost][unit.name] += 1

          @chached_targets[unit.uid] = nil

          @pathway.delete(unit)
        end
      end

      sync_data
    end

    def ready!
      @ready = true
    end

    def ready?
      @ready
    end

    def add_unit_to_pool(name)
      unit = Unit.new(name)
      @pathway << unit

      return [unit.uid, name, @uid]

      # units_available = @statistics[:units][:available][name] || 0

      # if units_available > 0
      #   @statistics[:units][:available][name] -= 1

      #   unit = Unit.new(name, rand(0..PATH_COUNT-1))
      #   @path_ways[unit.path_id] << unit

      #   return [unit.uid, name, @uid, unit.path_id]
      # end

      # nil
    end

    def destroy!
      @tower = nil

      @pathway.each do |unit|
        unit.target = nil
        unit = nil
      end

      @pathway = nil
    end

  end
end
