command do
  description "Kick yourself from the room to slay doppelgänger versions"
  action :optional => :reason do |msg,reason|
    if reason.nil?
        bot.room.kick(msg.sender.nick, 'no reason given')
    else
        bot.room.kick(msg.sender.nick, reason)
    end
  end
end
