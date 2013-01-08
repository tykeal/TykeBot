command do
  description "sets the XMPP status of the bot"
  action :required=>:s do |s|
    bot.config[:status]=s
    bot.status= s
    "set status to #{s}"
  end
end
