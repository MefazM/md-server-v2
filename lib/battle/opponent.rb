require 'lib/battle/entity/tower'
require 'lib/battle/entity/unit'
require 'lib/battle/send_proxy'

module Battle
  class Opponent

    attr_reader :username, :statistics, :tower, :pathway, :uid, :proxy

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

      @proxy = SendProxy.new(@uid)
    end

    def battle_data
      {
        uid: @uid,
        tower: @tower.to_a,
        units: @statistics[:units][:available]
      }
    end

    def units_at_front(segment_length = 15)
      positions = {}

      @pathway.each do |unit|
        segment_index = ((unit.position / segment_length) * 100).to_i
        segment_name = ['k', segment_index].join

        positions[segment_name] ||= {
          :count => 0,
          :pos => 0.0
        }

        if block_given?
          if yield(unit)
            positions[segment_name][:count] += 1
            positions[segment_name][:pos] += unit.position
          end
        else
          positions[segment_name][:count] += 1
          positions[segment_name][:pos] += unit.position
        end
      end

      matched, matches = positions.max_by{|_,u| u[:count]}

      return nil if matched.nil?

      avg_pos = matches[:pos] / matches[:count].to_f

      return avg_pos, matches[:count]
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

    def select(left, right)
      @pathway.each do |unit|
        next if unit == @tower

        yield unit if unit.position.between?(left, right)
      end
    end

    def get_target(attaker, opponent_units)

      target = @chached_targets[attaker.uid]
      unless target.nil? || target.dead?

        return target
      end

      opponent_units.find do |unit|
        if attaker.in_attack_range?(unit)

          count = @chached_targets.inject(0) do |c, (a, t)|
            c += (t.uid == unit.uid ? 1 : 0)
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

            @chached_targets[unit.uid] = target
          else
            unit.move(d_time) if unit.can_move?

            @chached_targets.delete(unit.uid)
          end
        end

        sync_data << unit.sync_data if unit.outdated?

        if unit.dead? && unit != @tower # do not track statistics for tower
          # Iterate lost unit counter
          @statistics[:units][:lost][unit.name] ||= 0
          @statistics[:units][:lost][unit.name] += 1

          @chached_targets.delete(unit.uid)

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
