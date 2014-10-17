# REQUESTS
module Receive
  LOGIN = :ln
  GAME_DATA = :gd
  HARVESTING = :hg


  NEW_BATTLE = :nb
  BATTLE_START = :bs
  LOBBY_DATA = :ld
  SPAWN_UNIT = :su
  UNIT_PRODUCTION_TASK = :upt
  CAST_SPELL = :cs
  RESPONSE_BATTLE_INVITE = :rbi
  PING = :pg
  BUILDING_PRODUCTION_TASK = :bpt

  CURRENT_MINE = :cm
  RELOAD_GAME_DATA = :rgb
end
#RESPONSE
module Send
  AUTHORISED = :ad
  GAME_DATA = :gd
  PONG = :png
  GOLD_STORAGE_CAPACITY = :gsc
end
