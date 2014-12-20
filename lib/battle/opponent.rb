require 'lib/battle/tower'
require 'lib/battle/unit'

module Battle
  class Opponent

    PATH_COUNT = 10

    attr_reader :spawned_units_count, :units_statistics, :path_ways,
                :main_building, :mana_data, :spells_statistics,
                :username, :level


    attr_reader :statistics, :tower

    def initialize(data)
      @uid = data[:uid]
      @ready = false

      @path_ways = Array.new(PATH_COUNT){[]}

      @tower = Tower.new(@uid)
      @tower.engaged_routes.each do |path_id|
        @path_ways[path_id] << @tower
      end

      @username = data[:username]

      @statistics = {
        units: {
          available: data[:units],
          lost: {}
        },
        spells: [],
        level: data[:level]
      }
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
      @path_ways.flatten.each do |unit|

        segment = ((unit.position / segment_length) * 100).to_i
        key = ['k', 'segment'].join

        positions[key] ||= {
          :count => 0,
          :pos => 0.0
        }

        if block_given?
          if yield(unit)
            positions[key][:count] += 1
            positions[key][:pos] += unit.position
          end
        else
          positions[key][:count] += 1
          positions[key][:pos] += unit.position
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
      @path_ways.each {|path_way| path_way.sort_by!{|v| v.position}.reverse!}
    end

    def update(opponent, iteration_delta)
      # First need to sort opponent units by distance
      opponent.sort_units!
      sync_data_arr = []

      @path_ways.each_with_index do |path, index|
        path.each do |unit|

          if unit.has_no_target? && !unit.dead?
            target = find_nearest(unit, opponent.path_ways)
            unless target.nil?

              unit.set_target(target)
              @path_ways[unit.path_id] << @path_ways[index].delete(unit)

              target.set_target(unit) if target.has_no_target?
            end
          end

          if unit.update(iteration_delta)
            sync_data_arr << unit.sync_data
          end

          if unit.dead? && unit != @tower # do not track statistics for tower
            # Iterate lost unit counter
            @statistics[:units][:lost][unit.name] ||= 0
            @statistics[:units][:lost][unit.name] += 1

            path.delete(unit)
            # @spawned_units_count -= 1
          end

        end
      end

      return sync_data_arr
    end

    def ready!
      @ready = true
    end

    def ready?
      @ready
    end

    def add_unit_to_pool(name)

      unit = Unit.new(name, rand(0..PATH_COUNT-1))
      @path_ways[unit.path_id] << unit

      return [unit.uid, name, @uid, unit.path_id]

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
      @path_ways.each do |path|
        path.each do |unit|
          unit.target = nil
          unit = nil
        end
      end

      @path_ways = nil
    end

    private

    def find_nearest(attaker, opponent_path_ways)
      closest_distance = -1.0
      target = nil
      attaker_position = attaker.position
      attaker_path_id = attaker.path_id

      target_min_path_way = attaker_path_id - 3
      target_min_path_way = 0 if target_min_path_way < 0
      target_max_path_way = attaker_path_id + 3
      target_max_path_way = 9 if target_max_path_way > 9


      self_units = 0
      @path_ways.each{|path_way| self_units += path_way.count }

      self_units = self_units * 0.1


      # opponent_path_ways[target_min_path_way..target_max_path_way].each_with_index do |path_way, index|
      opponent_path_ways.each_with_index do |path_way, index|

        nearest = path_way.find {|unit| (unit.position + attaker_position) < 1.0}
        next if nearest.nil?

        nearest_position = nearest.position

        distance = nearest_position + attaker_position

        next if distance < 0.02 && attaker_path_id != index
        next if distance > 0.96

        target_position = 1.0 - nearest_position


        next if (1.0 - distance).abs > 0.3
        # attack_offset = (attaker.attack_offset + nearest.attack_offset)
        # time
        # inverted_dist = (1.0 - distance) + attack_offset
        # horizontal_time = inverted_dist + 0.05 / ((attaker.movement_speed  + nearest.movement_speed))
        # vertical_time = (attaker_path_id - index).abs * 0.2
        # next if vertical_time > horizontal_time

        # ff = nearest_position - 0.125
        # ff = 0.0 if ff < 0.0

        # # if 1.0 - distance > 0.05
        count_between = @path_ways[index].select {|u|
          # u.position > attaker_position && u.position < nearest_position
          u.position.between?(attaker_position, attaker_position + 0.3)
        }.length

        next if count_between >= self_units + 1 #&& distance > 0.4
          # count_between2 = @path_ways[index].select {|u|
          #   # u.position > attaker_position && u.position < nearest_position



          #   u.position.between?(attaker_position , nearest_position)
          # }.length

        # next if count_between > 1 && attaker_path_id == index
        # next if count_between > 2
        # next if count_between >= self_units + 1 #&& distance > 0.4
        # next if count_between2 >= self_units + 1 #&& distance > 0.4

        if (distance > closest_distance)
          closest_distance = distance
          target = nearest
        end

      end

      if target.nil? && closest_distance > 0.4
        path_way = opponent_path_ways[target_min_path_way..target_max_path_way].sample
        target = path_way.last unless path_way.nil?
      end

      target
    end

  end
end
