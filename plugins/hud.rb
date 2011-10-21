
$bot.add_command(
  :syntax => 'hud',
  :description => 'link to the hud',
	:regex       => /^hud$/,
	:is_public   => true
) { "https://control.gist.com:3001/hud" }
