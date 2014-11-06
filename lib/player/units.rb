require 'lib/player/redis_mapper'

module Player
  class Units

    include RedisMapper

    def initialize(player_id)
      @player_id = player_id
      @redis_key = ['players', @player_id].join(':')

      fields = {
        units: {},
        units_queue: {}
      }

      restore_from_redis(@redis_key, fields){|v| JSON.parse(v, {symbolize_names: true})}

    end

    def enqueue(unit_data)
      group_by = unit_data[:depends_on_building_uid]
      uid = unit_data[:uid].to_sym

      @units_queue[group_by] = {} if @units_queue[group_by].nil?
      # If player has no tasks in group
      if @units_queue[group_by][uid].nil?
        @units_queue[group_by][uid] = {
          count: 1,
          construction_time: unit_data[:production_time]
        }
      else
        # Increase tasks number if such tasks exist in queue
        @units_queue[group_by][uid][:count] += 1
      end
    end

    def group_not_enqueued?(group_by)
      @units_queue[group_by.to_sym].nil? || @units_queue[group_by.to_sym].empty?
    end

    def group_next_task(group_by)
      @units_queue[group_by.to_sym].first
    end

    def complite_task(unit_data)
      group_by = unit_data[:depends_on_building_uid]
      uid = unit_data[:uid].to_sym

      raise "Broken units queue! Group #{group_by} not found!" if @units_queue[group_by].nil?
      raise "Broken units queue! Task #{uid} not found!" if @units_queue[group_by][uid].nil?

      @units_queue[group_by][uid][:count] -= 1

      if @units_queue[group_by][uid][:count] <= 0
        @units_queue[group_by].delete(uid)
      end
    end

    def export
      queue = {}
      ready = {}


    end

  # def units_in_queue_export
  #   current_time = Time.now.to_f
  #   queue = {}
  #   unless @units_queue.empty?
  #     @units_queue.each do |group_uid, group|
  #       queue[group_uid] = []

  #       group.each do |unit_uid, task|
  #         task_info = {
  #           :uid => unit_uid,
  #           :count => task[:count],
  #           # :production_time => task[:construction_time]
  #         }

  #         if task[:finish_at]
  #           # task_info[:started_at] = (( task[:finish_at] - current_time ) * 1000 ).to_i
  #           # task_info[:started_at] = (task[:started_at] * 1000 ).to_i
  #           task_info[:production_time] = (( task[:finish_at] - current_time ) * 1000 ).to_i

  #         end
  #         # Collect task
  #         queue[group_uid] << task_info
  #       end
  #     end
  #   end

  #   queue
  # end

  end
end
