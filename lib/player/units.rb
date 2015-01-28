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

      @timers_handlers = {}
    end

    def restore_queue
      @units_queue.each do |group_by, group|
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

            @timers_handlers[group_by] = yield(unit_uid, period)

            break
          end

          true

        end
      end
    end

    def enqueue(unit_data)
      group_by = unit_data[:depends_on_building_uid].to_sym

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

        @timers_handlers[group_by] = yield(uid, period)
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
    end

    def complite_group(group_by)
      @units_queue[group_by.to_sym][:tasks].each do |task|
        unit_uid = task[:uid].to_sym
        @units[unit_uid] = (@units[unit_uid] || 0) + task[:count]
      end

      @units_queue[group_by.to_sym][:tasks].clear

      handler = @timers_handlers[group_by.to_sym]
      handler.cancel unless handler.nil?
    end

    def complite(unit_data)
      group = @units_queue[unit_data[:depends_on_building_uid]]
      raise "Broken units queue! Group #{unit_data[:depends_on_building_uid]} not found!" if group.nil?
      uid = unit_data[:uid].to_sym
      @units[uid] = (@units[uid] || 0) + 1

      group[:tasks].shift if (group[:tasks].first[:count] -= 1) < 1

      if group[:tasks].first
        group[:started_at] = Time.now.to_i
        @timers_handlers[unit_data[:depends_on_building_uid]] = yield(group[:tasks].first[:uid], group[:construction_time])
      end

      save!
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

    def mass_remove_units(lost_units)
      lost_units.each do |uid, count|
        next unless @units.key?(uid)
        @units.delete(uid) if (@units[uid] -= count) < 1
      end

      save!
    end

  end
end
