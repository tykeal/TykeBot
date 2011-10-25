
# private command of 'puts'
$bot.add_command(
	:syntax  => 'puts <string>',
	:description => 'Write something to $stdout',
	:regex       => /^puts\s+(.+)$/
) do |sender, message|
	puts "#{sender} says '#{message}'"
	"'#{message}' written to $stdout"
end

