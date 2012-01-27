command :is_public=>false do # only admin can shutdown
  description 'Shut down Bot'
  action do |message|
  	puts "#{message.sender.admin?} shut down the bot"
  	bot.disconnect
  	exit
  end
end
