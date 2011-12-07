config :random, :default=>3, :description=>'1 in <random> chance that welcome fortune will fire'
config :timer_push, :default=>5400, :description=>'number of seconds to wait between messages before spewing a fotune on room idle'

command do
  description "Displays a fortune"
  action { fortune }
end

helper :fortune do |prefix|
  (prefix||'')+`/usr/bin/fortune`
end

last_active = Time.now
started = false

on :join do |bot|
  timer(2) { started = true }
end

on :welcome do |bot,message|
  if (started && rand(config.random) < 1)
    send(:text => fortune("Welcome %s! Here have a fortune:\n" % bot.sender(message)))
  end
end

on :firehose do |bot,message|
  last_active = Time.now if started && bot.sender(message) != bot.name
end

# setup idle fortune timer
init do
  last_sent = 0
  (check = Proc.new { 
    if last_sent.to_i < last_active.to_i && Time.now-last_active >= config.timer_push
      send :text=>fortune("It's been quiet too long.  I think we need a fortune to liven things up!\n\n") rescue error
      last_sent = Time.now
    end
    timer(600, &check)
  }).call
end
