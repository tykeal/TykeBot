welcome_started = false

bot.timer.add_timer(:timestamp=>Time.now + 2, :requestor=>'welcome_plugin') { welcome_started = true }

bot.welcome do |person|
  if welcome_started
    publish(:give_fortune,{:fortune_prefix=>"Welcome #{person}! Here have a fortune:\n"})
  end
  # Return nil because the handler expects a text return to send to the room
  nil
end
