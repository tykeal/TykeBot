command(:help, 
  :description=>'Display help for the given command, or all commands if no command is specified',
  :alias=>'?',
  :optional=>:command
) do |sender, cmd|

  # Returns the default help message describing the bot's command repertoire.
  # Commands are sorted alphabetically by name, and are displayed according
  # to the bot's and the commands's _public_ attribute.
  command_name = cmd.to_s.strip
  master = bot.master?(sender)
  commands = bot.commands(!master)
  if command_name.length == 0
    # Display help for all commands
    "I understand the following commands:\n\n" +
      commands.sort.map do |command|
        master_text="[%s] " % (command.plugin ? "#{command.plugin.name}:plugin":'builtin') if master
        command.syntax.join("\n") + "\n  %s%s" % [master_text,command.description]
      end.join("\n\n")
  else
    # Display help for the given command
    if command = commands.detect{|cmd| cmd.name==command_name}
      command.syntax.join("\n") + "\n  #{command.description}"
    else
       "I don't understand '#{command_name}' Try saying" +
          " 'help' to see what commands I understand."
    end
  end
end

