
$bot.add_command(
	:syntax      => 'about',
	:description => 'About me, the bot!',
	:regex       => /^about$/,
	:is_public   => true
) {
"I'm a chat bot, duh!

You can find my base source available by doing the following git clone:
git clone git@github.com:tykeal/TykeBot.git"
}
