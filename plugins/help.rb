command(:help, 
  :description=>'Display help for the given command, or all commands if no command is specified',
  :alias=>'?',
  :optional=>:command
) do |message, cmd|

  # Returns the default help message describing the bot's command repertoire.
  # Commands are sorted alphabetically by name, and are displayed according
  # to the bot's and the commands's _public_ attribute.
  command_name = cmd.to_s.strip
  master = bot.master?(message)
  commands = bot.commands(!master)
  if command_name.length == 0
    # Display help for all commands
    "I understand the following commands:\n" +
      commands.sort.map do |command|
        "  %s - %s" % [command.name,command.description]
      end.join("\n")
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

