stats={}
command(:stats,
  :optional => :action,
  :description => "show stats for the bot"
) do |message,action|
  action = (action || 'show').strip
  case action
  when 'clear'
    save_data({})
    stats = {}
  when 'show'
    bot.commands(!bot.master?(message)).sort.map{|cmd| "%s=%d" % [cmd.name,stats[cmd.name]||0]}.join("\n")
  else 
    "Sorry, I don't know how to stats #{action}"
  end
end

on :command_match do |cmd,*params|
  stats[cmd.name] ||= 0
  stats[cmd.name] += 1
  save_data(stats)
end

init do 
  commands = bot.commands
  (load_data||{}).each{|name,count| 
    stats[name] = count.to_i if commands.detect{|cmd| cmd.name.to_s==name.to_s }}
end
