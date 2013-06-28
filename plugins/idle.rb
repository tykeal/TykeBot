require 'ostruct'
config :timer_push, :default=>5400, :description=>'number of seconds to wait between messages before spewing a fotune on room idle'
config :commands, :default=>['fortune','commandfu','hot','quip'], :description=>'list of commands the bot will pick from to run on idle'

command do
  description "simulate idle condition"
  action do |msg|
    rand_cmd(msg)
  end
end

last_active = Time.now
on :firehose do |message|
  last_active = Time.now if !message.sender.bot? && message.room?
end

class FakeMessage
  attr_accessor :body, :from, :t
  def initialize(body, t, from); @body=body; @t=t; @from=from; end
  def type; @t; end
end

# this has to simulate 3 different cases
# 1) idle timer, no sender: respond to room
# 2) room triggered (room jid w/ nick sender): respond to room
# 3) individual triggered (jid sender): respond to jid
helper :rand_cmd do |msg|
  send :to=>msg && msg.chat? ? msg.sender.jid : nil, :text=>"It's been quiet too long.  I think we need to liven things up!"
  # fake a tykemessage for now...
  fake = TykeMessage.new bot, FakeMessage.new(
    config[:commands].sample,
    msg ? msg.type : :groupchat,
    msg ? msg.sender.to_s : bot.config[:jid]
  )
  publish(:command, fake) 
end


# setup idle timer
on :join do
  last_sent = 0 
  (check = Proc.new { 
    if last_sent.to_i < last_active.to_i && Time.now-last_active >= config.timer_push
      rand_cmd(nil)
      last_sent = Time.now
    end 
    timer(600, &check)
  }).call
end

