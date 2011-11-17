forcedevent = nil
started = false

def get_fortune
  `/usr/bin/fortune`
end

command(:fortune,:description => 'get a fortune') { get_fortune() }

subscribe :join do |bot|
  bot.timer.add_timer(:timestamp=>Time.now + 2, :requestor=>'fortune_plugin_join') { started = true }
end

subscribe :welcome do |bot,message|
  if (rand(@config_memo[:random]) < 1)
    bot.send(:text => "Welcome %s! Here have a fortune:\n%s" % [bot.sender(message),get_fortune]) if started
  end
end

subscribe :firehose do |bot,message|
  if (!(bot.sender(message) == bot.config[:name]) && started)
    forcedevent = Time.now + @config_memo[:timer_push]
  end
end

subscribe :give_fortune do |bot|
  forcedevent = Time.now + @config_memo[:timer_push] if forcedevent.nil?
  bot.timer.add_timer(:timestamp=>Time.now + 15, :requestor=>'fortune_plugin_idle') {
    if (forcedevent <= Time.now)
      # push the forced event out again but make it twice as long
      forcedevent = Time.now + 2*@config_memo[:timer_push]
      bot.send(:text=>"It's been quiet too long.  I think we need a fortune to liven things up!\n\n%s" % [get_fortune])
    end
    publish(:give_fortune, bot)
  }
end

init do
  config()
  # just give our random welcome fortune a small chance
  # can be set in config yaml
  @config_memo[:random] ||= 3
  @config_memo[:timer_push] ||= 5400 # 90 minutes
  publish(:give_fortune, bot)
end
