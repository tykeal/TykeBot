command do
  description "show information about who is in the room"
  action do
    bot.room.roster.keys.join(", ")
  end
end
