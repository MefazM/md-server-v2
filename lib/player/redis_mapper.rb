module Player
  module RedisMapper

    def restore_from_redis(path, attrs)
      attrs.each do |field_name, default_value|
        Storage.redis_pool.with do |conn|
          value = conn.hget(path, field_name)

          if value.nil?
            value = default_value
          elsif block_given?
            value = yield(value)
          end

          instance_variable_set("@#{field_name}", value)
        end
      end
    end

    def save_to_redis(path, attrs)
      attrs.each do |field_name|
        Storage.redis_pool.with do |conn|
          value = instance_variable_get("@#{field_name}")
          value = yield(value) if block_given?

          conn.hset(path, field_name, value)
        end
      end

    end

  end
end
