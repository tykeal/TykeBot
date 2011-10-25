
$bot.add_command(
	:syntax      => 'about',
	:description => 'About me, the bot!',
	:regex       => /^about$/,
	:is_public   => true
) {
"I'm a chat bot, duh!

You can find my base source available by doing one of the following git clones:

read/write access (request access through github)
git clone git@github.com:tykeal/TykeBot.git

read only access
git clone git://github.com/tykeal/TykeBot.git"
}
