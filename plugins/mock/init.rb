config :insults, :description=>'list of insults with which to mock...'

command do
  description "Makes the bot mock a poor soul..."

  action do 
    "Currently mocking #{mockers.inspect}."
  end

  action :required=>:nick do |msg,nick|
    new_mockers = Array(mockers)
    if mock? nick
      new_mockers.delete nick
      save_data(new_mockers)
      "I will no longer mock #{nick}..."
    else
      new_mockers << nick
      save_data(new_mockers)
      "I will now be ruthlessly mocking #{nick}!"
    end
  end
end

on :firehose do |bot,msg|
  insult msg.sender.nick if !msg.sender.bot? and mock? msg.sender.nick
end

helper :mock? do |nick|
  mockers.include? nick
end

helper :insult do |nick|
  send :text=>"#{nick}: #{config.insults.sample}"
end

helper :mockers do
  (load_data||[])
end

