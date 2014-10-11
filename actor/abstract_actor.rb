class AbstractActor
  def act message, sender_uid
    raise 'Un implemented!'
  end

  def send_data message, conn_uid
    Server.send_data(message, conn_uid)
  end
end