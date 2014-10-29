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
      }){|v| JSON.parse(v, {symbolize_names: true})}
    end

    def queue
      @buildings_queue
    end

    def update_data(uid)
      target_level = (@buildings[uid] || 0) + 1
      Storage::GameData.building("#{uid}_#{target_level}")
    end

    def updateable?(uid)
      @buildings_queue[uid].nil? and update_data(uid) != nil
    end

    def complite_update(uid)
      return nil if @buildings_queue[uid].nil?
      update = @buildings_queue[uid]
      @buildings_queue.delete(uid)
      # update building level in the hash
      @buildings[uid] = update[:level]

      update
    end

    def push_update(update)
      @buildings_queue[update[:uid].to_sym] = {
        adding_time: Time.now.to_i,
        construction_time: update[:production_time],
        level: update[:level],
        uid: update[:uid]
      }
    end

    def coins_mine_level
      @buildings[Storage::GameData.coin_generator_uid] || 0
    end

    def coins_storage_level
      @buildings[Storage::GameData.storage_building_uid] || 0
    end

    def export
      buildings = {}

      @buildings.each do |uid, level|
        buildings[uid] = {level: level, ready: true, uid: uid}
      end

      unless @buildings_queue.empty?
        @buildings_queue.each do |uid, update|
          time_left = update[:construction_time] - (Time.now.to_i - update[:adding_time])
          buildings[uid] = {
            finish_time: time_left,
            construction_time: update[:construction_time],
            level: update[:level],
            uid: uid
          }
        end
      end

      buildings
    end

    def save!
      save_to_redis(@redis_key, [:buildings, :buildings_queue]){|value| JSON.generate(value)}
    end

  end
end