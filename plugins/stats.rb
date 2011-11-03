stats={}
command(:stats,
  :optional => :action,
  :description => "show stats for the bot"
) do |message,action|
  action = (action || 'show').strip
  case action
  when 'clear'
    data_save_yaml({})
    stats = {}
  when 'show'
    bot.commands(!bot.master?(sender)).sort.map{|cmd| "%s=%d" % [cmd.name,stats[cmd.name]||0]}.join("\n")
  else 
    "Sorry, I don't know how to stats #{action}"
  end
end

subscribe :command_match do |cmd,*params|
  stats[cmd.name] ||= 0
  stats[cmd.name] += 1
  data_save_yaml(stats)
end

init do 
  commands = bot.commands
  (data_load_yaml||{}).each{|name,count| 
    stats[name] = count.to_i if commands.detect{|cmd| cmd.name.to_s==name.to_s }}
end
