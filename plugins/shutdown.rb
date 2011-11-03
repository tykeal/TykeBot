# only master can shutdown
command(:shutdown,
	:description => 'Shut down Bot',
	:is_public   => false
) do |message|
	puts "#{bot.sender(message)} shut down the bot"
	bot.disconnect
	exit
end

