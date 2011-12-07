command do
  aliases '?'
  description 'Display help information.'

  action :description=>'list all commands' do |message|
    "I understand the following commands:\n" +
      commands(message).sort.map{|command|
        "  %s - %s" % [command.names.join("|"),command.description]}.join("\n")
  end

  action :required=>:command_name, 
    :description=>'show usage for the specified command' do |message,command_name|
    if command = commands.detect{|cmd| cmd.names.map(&:to_s).include?(command_name)}
      "#{command.names.join("|")} - #{command.description}\nUsage:\n" + 
        actions(message,command).map{ |a| syntax(command,a) }.join("\n")
    else
       "unknown command #{command_name}."
    end
  end
end

helper :commands do |message|
  bot.commands(!bot.master?(message))
end

helper :actions do |message,command|
  command.actions.select{|a|a.public?||bot.master?(message)}
end

helper :syntax do |c,a|
  "%s%s%s" % [c.name,a.name? ? " #{a}" : a,a.description ? " - #{a.description}" : '']
end
