require 'lib/player/redis_mapper'

module Player
  class Buildings

    include RedisMapper

    def initialize(player_id)
      @player_id = player_id
      @redis_key = ['players', @player_id].join(':')

      restore_from_redis(@redis_key, {
        buildings: {},
        buildings_queue: {}
      }){|v| JSON.parse(v, {:symbolize_names => true})}

    end

    def update(building_uid, construction_time, level)
      # @buildings_queue[building_uid] = {
      #   :finish_at => construction_time + Time.now.to_f,
      #   :construction_time => construction_time,
      #   :level => level
      # }
    end

    def building_ready?(uid)
      # !@buildings_queue[uid].nil?
    end

    # def process_buildings_queue current_time
    #   @buildings_queue.each do |building_uid, task|
    #     if task[:finish_at] < current_time
    #       @buildings_queue.delete(building_uid)
    #       # Each building stores in uid:level pair.
    #       # @buildings[building_uid].nil? - means that building has 0 level
    #       if @buildings[building_uid].nil?
    #         @buildings[building_uid] = 1
    #       else
    #         # After update - increase building level
    #         @buildings[building_uid] += 1
    #       end

    #       send_sync_building_state(building_uid, @buildings[building_uid])

    #       after_building_updates building_uid
    #     end
    #   end
    # end

    # def after_building_updates building_uid
    #   case building_uid
    #   # update coins storage
    #   when @storage_building_uid
    #     compute_storage_capacity
    #     send_coins_storage_capacity
    #   end
    # end

    def to_hash
      queue = {}
      unless @buildings_queue.empty?
        current_time = Time.now.to_f
        @buildings_queue.each do |building_uid, task|
          task_info = {
            :finish_time => (task[:finish_at] - Time.now.to_f) * 1000,
            :construction_time => task[:construction_time],
            :level => task[:level],
            :uid => building_uid
          }

          queue[building_uid] = task_info
        end
      end

      {
        buildings: @buildings,
        queue: queue
      }
    end

  end
end