# REQUESTS
module Receive
  LOGIN = :ln
  GAME_DATA = :gd
  HARVESTING = :hg

  PING = :pg

  CONSTUCT_BUILDING = :cb
  CONSTUCT_UNIT = :cu

  UPDATE_LOBBY_DATA = :uld

  INVITE_OPPONENT_TO_BATTLE = :iotb
  RESPONSE_INVITATION_TO_BATTLE = :ritb

  READY_TO_BATTLE = :rtb
  CAST_SPELL = :cs
  SPAWN_UNIT = :spu

  CREATE_AI_BATTLE = :cab
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

  SYNC_UNITS = :su

  UPDATE_LOBBY_DATA = :uld

  INVITE_TO_BATTLE = :itb
  CANCEL_INVITE = :ci

  CREATE_NEW_BATTLE = :cnb
  CAST_SPELL = :cs
  SPAWN_UNIT = :spu
  START_BATTLE = :stb
  FINISH_BATTLE = :fshb
  SYNC_BATTLE = :syb

  SPELL_ICONS = :asi
end
