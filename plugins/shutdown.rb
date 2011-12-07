command :is_public=>false do # only master can shutdown
  description 'Shut down Bot'
  action do |message|
  	puts "#{bot.sender(message)} shut down the bot"
  	bot.disconnect
  	exit
  end
end
