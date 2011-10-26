plugin.add_command(
  :syntax       => 'help [<command>]',
  :description  => 'Display help for the given command, or all commands' +
      ' if no command is specified',
  :regex        => /^help(\s+.+?)?$/,
  :alias        => [ :syntax => '? [<command>]', :regex => /^\?(\s+.+?)?$/ ],
  :is_public    => plugin.bot.config[:is_public]
) do |sender, cmd|

  # Returns the default help message describing the bot's command repertoire.
  # Commands are sorted alphabetically by name, and are displayed according
  # to the bot's and the commands's _public_ attribute.
  command_name = (cmd || '').strip
  if command_name.length == 0
    # Display help for all commands
    help_message = "I understand the following commands:\n\n"

    plugin.bot.commands[:meta].sort.each do |command|
      command = command[1]

      if !command[:is_alias] && (command[:is_public] || plugin.bot.master?(sender))
        command[:syntax].each { |syntax| help_message += "#{syntax}\n" }
        help_message += "  #{command[:description]}\n\n"
      end
    end
  else
    # Display help for the given command
    command = plugin.bot.commands[:meta][command_name]

    if command.nil?
        help_message = "I don't understand '#{command_name}' Try saying" +
          " 'help' to see what commands I understand."
    else
      help_message = ''
      command[:syntax].each { |syntax| help_message += "#{syntax}\n" }
      help_message += "  #{command[:description]} "
    end
  end

  help_message

end

