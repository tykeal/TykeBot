def updatescript
  `#{config[:update_script]}`
end

command(:update, :description => 'Make bot update to the latest revision', :is_public => false) {
  updatescript
}

add_command(
  :syntax => 'GitUpdateHandler',
  :description => 'Internal command for updating based upon GitHub updates',
  :regex => /^\[TykeBot\] (\w+) pushed \d+ new commits to master:.+$/
) do |message,who|
  if (bot.sender(message) == 'github-services@jabber.org' && who != 'none')
    bot.send(:text=>'A checkin on GitHub has initiated a bot update, one moment please...')
    updatescript
  end
end

init do
  config[:update_script] ||= '~/deploy/tykebot/current/scripts/run_update.sh'
end
