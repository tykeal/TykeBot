config :insults, :description=>'list of insults with which to mock...'

command do
  description "Makes the bot mock a poor soul..."

  action do 
    "Currently mocking #{mockers.inspect}."
  end

  action :required=>:nick do |msg,nick|
    if mock? nick
      save_data(mockers.delete nick)
      "I will no longer mock #{nick}..."
    else
      save_data(mockers << nick)
      "I will now be ruthlessly mocking #{nick}!"
    end
  end
end

on :firehose do |bot,msg|
  insult msg.sender.nick if mock? msg.sender.nick
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

