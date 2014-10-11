#!/usr/bin/env ruby
require 'pry'
require 'version'
require 'server/server'
require 'actor/overlord'

require 'actor/login_actor'
require 'storage/storage'

Thread.abort_on_exception = true

Storage.configure do |conf|
  conf.redis_pool_size = 20
  conf.mysql_pool_size = 20
  conf.host = 'localhost'
  conf.db_name = 'game_cms'
  conf.user_name = 'root'
  conf.password = ''
end
Storage.create!

Overlord.configure do |conf|
  conf.num_threads = 10
end
Overlord.run!

Overlord.observe(:login, LoginActor.new)

Server.configure do |conf|
  conf.ip = '0.0.0.0'
  conf.port = '27014'
end
Server.dispatch!
