config :update_script, :default=>'~/deploy/tykebot/current/scripts/run_update.sh', :description=>'The script to run when update is called'
config :github_jid, :default=>'github-services@jabber.org', :description=>'jabber id of the github xmpp hook'

command do
#  aliases '[TykeBot]' # a small hack to make this work...
  description 'Make bot update to the latest revision'

  action :is_public=>false do |message|
    send(:text=>"One of my masters told me I need an update.  One moment please...")
    timer(3){updatescript}
    # Emit to my caller that I'm doing something instead of
    # spitting out function pointers
    'starting my update'
  end

end

on :firehose do |bot,message|
  if message.body != nil
    if message.sender.jid == config.github_jid
      # log that that we got a message from github to help debug
      puts "message from GitHub: '#{message.body}'"
    end
    info = message.body.match(/^\[TykeBot\] (\w+) pushed (\d+) new commits? to master:/)
    if message.sender.jid == config.github_jid && info
      # details = message.body.match(/^\[TykeBot\] (.+)$/)
      details = message.body
      # info[1] is who, info[2] is number of commits
      bot.send(:text=>"A checkin on GitHub by #{info[1]} has initiated a bot update.  One moment please...\n\n#{details}")
      # give it a few seconds to let the room know...
      timer(3){updatescript}
    end
  end
end

helper :updatescript do
  `#{config.update_script}`
end
