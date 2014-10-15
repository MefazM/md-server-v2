require 'lib/player/redis_mapper'

module Player
  class Units

    include RedisMapper

    def initialize(player_id)
      @player_id = player_id
      @redis_key = ['players', @player_id].join(':')

      restore_from_redis(@redis_key, {
        units: {},
        units_queue: {}
      }){|v| JSON.parse(v, {:symbolize_names => true})}

    end

  end
end
