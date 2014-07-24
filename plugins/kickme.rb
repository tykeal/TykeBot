command do
  description "Kick yourself from the room to slay doppelgänger versions"
  action :required => :reason do |msg,reason|
    bot.room.kick(msg.sender.nick, reason)
  end
end
