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

  CONSTUCT_BUILDING = :cb
  CONSTUCT_UNIT = :cu
end
#RESPONSE
module Send
  AUTHORISED = :ad
  GAME_DATA = :gd
  PONG = :png
  GOLD_STORAGE_CAPACITY = :gsc
  NOTIFICATION = :ntct

  BUILDING_SYNC = :bsc

  SCORE_SYNC = :scs
  MANA_SYNC = :mns

  START_GAME_SCENE = :sgs

  PUSH_UNIT_CONSTRUCTION_TASK = :psut
  POP_UNIT_CONSTRUCTION_TASK = :poct
end
