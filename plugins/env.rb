env={
  "ME"=>proc{|bot,message| message.sender.display},
  "ROOM"=>proc{|bot,message| bot.config[:room]},
  "BOT"=>proc{|bot,message| bot.name},
}

command do
  description 'env vars'
  action do |message|
    env.keys.sort.map{|k| "#{k}=#{env[k].call(bot,message)}"}.join("\n")
  end
end

before(:command) do |bot,message|
  env.each do |name,f| 
    message.body = message.body.to_s.gsub(/(^|[^\\])\$#{name}/,"\\1#{f.call(bot,message)}")
  end
end
