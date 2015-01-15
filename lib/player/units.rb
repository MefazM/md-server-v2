require 'lib/player/redis_mapper'

module Player
  class Units

    include RedisMapper

    def initialize(player_id)
      @redis_key = ['players', player_id].join(':')
      fields = {
        units: {},
        units_queue: {}
      }
      restore_from_redis(@redis_key, fields){|v| JSON.parse(v, {symbolize_names: true})}
    end

    def restore_queue
      not_ready_tasks = []
      @units_queue.each_value do |group|
        elapsed_time = Time.now.to_f - group[:started_at]
        group[:tasks].delete_if do |task|
          unit_uid = task[:uid].to_sym
          info = Storage::GameData.unit(unit_uid)
          progress = elapsed_time / info[:production_time]

          ready_count = [progress.floor, task[:count]].min
          @units[unit_uid] = (@units[unit_uid] || 0) + ready_count

          elapsed_time -= ready_count * info[:production_time]

          if (task[:count] -= ready_count) > 0
            period = (1.0 - (progress % 1)) * info[:production_time]
            group[:started_at] = Time.now.to_i - (info[:production_time] - period)
            group[:construction_time] = info[:production_time]

            not_ready_tasks << [unit_uid, period]

            break
          end

          true

        end
      end

      not_ready_tasks
    end

    def enqueue(unit_data)
      group_by = unit_data[:depends_on_building_uid].to_sym
      first_in_queue = false
      @units_queue[group_by] = {
        started_at: nil,
        tasks: []
      } if @units_queue[group_by].nil?

      period = unit_data[:production_time]
      uid = unit_data[:uid]

      group = @units_queue[group_by]

      if group[:tasks].empty?
        group[:started_at] = Time.now.to_i
        group[:construction_time] = period

        first_in_queue = true
      end

      task = group[:tasks].find{|t| t[:uid] == uid }

      if task.nil?
        group[:tasks] << {
          uid: uid,
          count: 1
        }
      else

        task[:count] += 1
      end

      save!

      first_in_queue
    end

    def complite(unit_data)
      group = @units_queue[unit_data[:depends_on_building_uid]]
      raise "Broken units queue! Group #{unit_data[:depends_on_building_uid]} not found!" if group.nil?
      uid = unit_data[:uid].to_sym
      @units[uid] = (@units[uid] || 0) + 1

      group[:tasks].shift if (group[:tasks].first[:count] -= 1) < 1

      return nil unless group[:tasks].first
      group[:started_at] = Time.now.to_i

      save!

      [group[:tasks].first[:uid], group[:construction_time]]
    end

    def export
      {
        units: @units,
        queue: @units_queue
      }
    end

    def save!
      save_to_redis(@redis_key, [:units, :units_queue]){|value| JSON.generate(value)}
    end

    def mass_remove_units(units)
      units.each {|uid, count| @units.delete(uid) if (@units[uid] -= count) < 1 }
      save!
    end

  end
end
