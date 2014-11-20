#!/usr/bin/env ruby
require 'pry'
require 'version'
require 'server/server'
require 'lib/reactor'

require 'storage/storage'
require 'dotenv'

require 'json'

Dotenv.load

Thread.abort_on_exception = true

Storage.configure do |conf|
  conf.redis_pool_size = ENV['REDIS_POOL_SIZE']
  conf.mysql_pool_size = ENV['MYSQL_POOL_SIZE']
  conf.host = ENV['HOST']
  conf.db_name = ENV['DB_NAME']
  conf.user_name = ENV['USER_NAME']
  conf.password = ENV['PASSWORD']
  conf.game_settings_yml_path = ENV['GAME_SETTINGS_YML_PATH']
end

Storage.setup!

Reactor.configure do |conf|
  conf.num_threads = ENV['NUM_THREADS']
end

Reactor.run!

Server.configure do |conf|
  conf.ip = ENV['IP']
  conf.port = ENV['PORT']
end

Server.dispatch!
