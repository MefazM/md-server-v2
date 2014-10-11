require 'actor/abstract_actor'

class PlayerActor < AbstractActor

  def initialize(id, email, username)

  end

  def act message, sender_uid

    puts "PLAYER!!: #{message.inspect}"

  end

end