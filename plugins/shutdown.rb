# only master can shutdown
command(:shutdown,
	:description => 'Shut down Bot',
	:is_public   => false
) do |from, msg|
	puts "#{from} shut down the bot"
	plugin.bot.disconnect
	exit
end

