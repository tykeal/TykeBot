
# only a master may tell the bot to shutdown
plugin.add_command(
	:syntax => 'shutdown',
	:description => 'Shut down Bot',
	:is_public   => false,
	:regex       => /^shutdown$/
) do |from, msg|
	puts "#{from} shut down the bot"
	plugin.bot.disconnect
	exit
end

