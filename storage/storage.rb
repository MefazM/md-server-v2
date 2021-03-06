require 'connection_pool'

require 'storage/mysql_client'
require 'redis'

require 'storage/game_data'
require 'lib/logger'

module Storage
  class << self

    attr_accessor :redis_pool_size, :mysql_pool_size,
                  :host, :db_name, :user_name, :password,
                  :game_settings_yml_path

    attr_reader :mysql_pool, :redis_pool

    def configure
      yield self

    end

    def setup!
      TheLogger.info 'Create redis and mysql connections pools...'
      @mysql_pool ||= ConnectionPool.new(size: @mysql_pool_size) { MysqlClient.new(@host, @db_name, @user_name, @password)}
      @redis_pool ||= ConnectionPool.new(size: @redis_pool_size) { Redis.new }

      TheLogger.info 'Load and process game data...'

      GameData.load! @game_settings_yml_path
    end
  end
end