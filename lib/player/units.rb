require 'lib/player/redis_mapper'

module Player
  class Units

    include RedisMapper

    def initialize(player_id, connection_uid)
      @connection_uid = connection_uid
      @redis_key = ['players', player_id].join(':')

      fields = {
        units: {},
        units_queue: {}
      }

      restore_from_redis(@redis_key, fields){|v| JSON.parse(v, {symbolize_names: true})}

      @units_queue.keys.each{|group_by| process_group_queue(group_by)}
    end

    def process_group_queue(group_by)
      start_time = @units_queue[group_by][:started_at]
      elapsed_time = Time.now.to_i - start_time

      @units_queue[group_by][:tasks].each do |task|
        unit_uid = task[:uid].to_sym
        task[:count].times do |i|

          construction_time = @units_queue[group_by][:construction_time]

          if construction_time < elapsed_time

            elapsed_time -= construction_time
            @units[unit_uid] = (@units[unit_uid] || 0) + 1
            task[:count] -= 1
          else
            period = construction_time - elapsed_time
            @units_queue[group_by][:started_at] = Time.now.to_i - elapsed_time

            Reactor.perform_after(period, [@connection_uid, :unit_production_ready, unit_uid])
            return
          end

        end

        @units_queue[group_by][:tasks].shift
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

      if @units_queue[group_by][:tasks].empty?
        @units_queue[group_by][:started_at] = Time.now.to_i
        @units_queue[group_by][:construction_time] = period

        Reactor.perform_after(period, [@connection_uid, :unit_production_ready, uid])
      end

      task = @units_queue[group_by][:tasks].find{|t| t[:uid] == uid }

      if task.nil?
        @units_queue[group_by][:tasks] << {
          uid: uid,
          count: 1
        }
      else

        task[:count] += 1
      end
    end

    def complite_and_enque(unit_data)
      group_by = unit_data[:depends_on_building_uid]
      uid = unit_data[:uid].to_sym

      raise "Broken units queue! Group #{group_by} not found!" if @units_queue[group_by].nil?

      @units[uid.to_sym] = (@units[uid.to_sym] || 0) + 1

      count = @units_queue[group_by][:tasks].first[:count] -= 1

      if count < 1
        @units_queue[group_by][:tasks].shift
      end

      task = @units_queue[group_by][:tasks].first
      unless task.nil?
        period = @units_queue[group_by][:construction_time]
        @units_queue[group_by][:started_at] = Time.now.to_i
        Reactor.perform_after(period, [@connection_uid, :unit_production_ready, task[:uid]])
      end
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
  end
end
