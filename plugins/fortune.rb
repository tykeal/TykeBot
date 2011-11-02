forcedevent = nil
started = false

def get_fortune
  `/usr/bin/fortune`
end

command(:fortune,:description => 'get a fortune') { get_fortune() }

subscribe :join do |bot|
  bot.timer.add_timer(:timestamp=>Time.now + 2, :requestor=>'fortune_plugin') { started = true }
end

subscribe :welcome do |bot,message|
  bot.send(:text => "Welcome %s! Here have a fortune:\n%s" % [bot.sender(message),get_fortune]) if started
end

