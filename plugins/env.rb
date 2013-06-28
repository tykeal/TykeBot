env={
  "ME"=>proc{|message| message.sender.display},
  "ROOM"=>proc{|message| bot.config[:room]},
  "BOT"=>proc{|message| bot.name},
}

command do
  description 'env vars'
  action do |message|
    env.keys.sort.map{|k| "#{k}=#{env[k].call(message)}"}.join("\n")
  end
end

before(:command) do |message|
  env.each do |name,f| 
    message.body = message.body.to_s.gsub(/(^|[^\\])\$#{name}/,"\\1#{f.call(message)}")
  end
end
