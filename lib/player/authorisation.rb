module Player
  module Authorisation

    def not_authorized?
      @player_id.nil?
    end

    def authorise!(login_data)
      @player_id, @email, @username = find_or_create(login_data)
    end

    private

    def find_or_create(login_data)
      TheLogger.info "Player logging in (Token = #{login_data[:token]})"

      authentication = Storage.mysql_pool.with do |conn|
        conn.select("SELECT * FROM authentications WHERE token = '#{login_data[:token]}'").first
      end

      player_id = authentication.nil? ? create_player(login_data) : authentication[:player_id]

      get_player_data(player_id)
    end

    private

    def create_player(login_data)
      player_id = Storage.mysql_pool.with do |conn|

        id = conn.insert('players', {email: login_data[:email], username: login_data[:name]})

        raise "Player is not created! \n #{login_data.inspect}" if id == -1

        data = {player_id: id, provider: login_data[:provider], token: login_data[:token]}
        conn.insert('authentications', data)

        id
      end

      TheLogger.info "New player created. id = #{player_id}"

      # Storage.redis_pool.with do |redis|
      #   redis.hset("players:#{player_id}:resources", "last_harvest_time", Time.now.to_i)
      #   redis.hset("players:#{player_id}:resources", 'coins', 0)
      #   redis.hset("players:#{player_id}:resources", 'harvester_storage', 0)
      #   redis.hset("players:#{player_id}:resources", "last_mana_compute_time", Time.now.to_i)
      # end

      player_id
    end

    def get_player_data(id)
      player_data = Storage.mysql_pool.with do |conn|
        conn.select("SELECT * FROM players WHERE id = '#{id}' ").first
      end

      raise "Authentication find, but player data is not found!" if player_data.nil?

      return id, player_data[:email], player_data[:username]
    end

  end
end
