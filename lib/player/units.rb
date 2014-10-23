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

      restore_from_redis(@redis_key, fields) do |field|
        JSON.parse(field, {:symbolize_names => true})
      end

    end

  end
end
