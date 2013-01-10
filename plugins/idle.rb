require 'ostruct'
config :timer_push, :default=>5400, :description=>'number of seconds to wait between messages before spewing a fotune on room idle'
config :commands, :default=>['fortune','commandfu','hot','quip'], :description=>'list of commands the bot will pick from to run on idle'

command do
  description "simulate idle condition"
  action do
    rand_cmd
  end
end

last_active = Time.now
started = false

on :join do |bot|
  timer(2) { started = true }
end

on :firehose do |bot,message|
  last_active = Time.now if started && !message.sender.bot? && message.room?
end

helper :rand_cmd do
  send :text=>"It's been quiet too long.  I think we need to liven things up!"
  # fake a tykemessage for now...
  msg = TykeMessage.new bot, OpenStruct.new(
    :body=>config[:commands].sample,
    :type=>:groupchat,
    :from=>bot.config[:jid]
  )
  publish(:command, bot, msg) 
end

# setup idle timer
init do
  last_sent = 0 
  (check = Proc.new { 
    if last_sent.to_i < last_active.to_i && Time.now-last_active >= config.timer_push
      rand_cmd
      last_sent = Time.now
    end 
    timer(600, &check)
  }).call
end

