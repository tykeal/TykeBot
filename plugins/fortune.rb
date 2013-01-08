config :random, :default=>3, :description=>'1 in <random> chance that welcome fortune will fire'

command do
  description "Displays a fortune"
  action { fortune }
end

helper :fortune do |prefix|
  (prefix||'')+`/usr/bin/fortune`
end

started = false

on :join do |bot|
  timer(2) { started = true }
end

on :welcome do |bot,message|
  if (started && rand(config.random) < 1)
    send(:text => fortune("Welcome %s! Here have a fortune:\n" % message.sender.nick))
  end
end

