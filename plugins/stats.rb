stats={}
command do
  description "show stats for the bot"

  action :show, :default=>true do |message|
    bot.commands(!bot.master?(message)).sort.map{|cmd| "%s=%d" % [cmd.name,stats[cmd.name]||0]}.join("\n")
  end

  action :clear do |message|
    save_data({})
    stats = {}
  end
end
  
on :command_match do |cmd,*params|
  stats[cmd.name] ||= 0
  stats[cmd.name] += 1
  save_data(stats)
end

init do 
  # load stat counts
  commands = bot.commands
  (load_data||{}).each{|name,count| 
    stats[name] = count.to_i if commands.detect{|cmd| cmd.name.to_s==name.to_s }}
end
