require 'lib/abstract_actor'
require 'actors/player_actor'
require 'lib/logger'

class LoginActor < AbstractActor

  def initialize
    @players_connections_map = ThreadSafe::Cache.new
  end

  def act message, sender_uid
    id, email, username = find_or_create message

    player_id = ['player_', id].join.to_sym

    if @players_connections_map[player_id]
      TheLogger.warn "Player already connected! Drop previous connection..."
      old_connection_uid = @players_connections_map[player_id]
      Server.connections[old_connection_uid].close_connection_after_writing
    end

    if Overlord.not_exists? player_id
      Overlord.observe(player_id, Player::Actor.new(id, email, username))
    end

    Server.connections[sender_uid].authorize! id

    @players_connections_map[player_id] = sender_uid

    send_data(['authorised', Overlord[player_id].initialization_data], sender_uid)
  end

  private

  def find_or_create login_data
    TheLogger.info "Player logging in (Token = #{login_data[:token]})"

    authentication = Storage.mysql_pool.with do |conn|
      conn.select("SELECT * FROM authentications WHERE token = '#{login_data[:token]}'").first
    end

    player_id = authentication.nil? ? create_player(login_data) : authentication[:player_id]

    get_player_data(player_id)
  end

  private

  def create_player login_data
    player_id = Storage.mysql_pool.with do |conn|

      id = conn.insert('players', {:email => login_data[:email], :username => login_data[:name]})

      raise "Player is not created! \n #{login_data.inspect}" if id == -1

      data = {:player_id => id, :provider => login_data[:provider], :token => login_data[:token]}
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

  def get_player_data id
    player_data = Storage.mysql_pool.with do |conn|
      conn.select("SELECT * FROM players WHERE id = '#{id}' ").first
    end

    raise "Authentication find, but player data is not found!" if player_data.nil?

    return id, player_data[:email], player_data[:username]
  end

end