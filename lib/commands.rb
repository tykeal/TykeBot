# mixin for dealing with commands
module Commands

    # Add a command to the bot's repertoire.
    #
    # Commands consist of a metadata Hash and a callback block. The metadata
    # Hash *must* contain the command +syntax+, a +description+ for display with
    # the builtin 'help' command, and a regular expression (+regex+) to detect
    # the presence of the command in an incoming message.
    #
    # The command parameter(s) will be parsed from group(s) (text between
    # parenthesis) in the +regex+. If there's none, one, or more than one
    # occurrence, the callback block will receive respectively nil, a String,
    # or an Array.
    # e.g. With a command defined like this: /^cmd\s+(.+)\s+(.+)\s+(.+)$/,
    # writing "cmd foo bar 42" will send ["foo", "bar", "42"] to the callback
    # block.
    #
    # The metadata Hash may optionally contain an array of command aliases. An
    # +alias+ consists of an alias +syntax+ and +regex+. Aliases allow the bot
    # to understand command shorthands. For example, the default 'help' command
    # has an alias '?'. Saying either 'help' or '?' will trigger the same
    # command callback block.
    #
    # The metadata Hash may optionally contain a +is_public+ flag, indicating
    # the bot should respond to *anyone* issuing the command, not just the bot
    # master(s). Public commands are only truly public if the bot itself has
    # been made public.
    #
    # The specified callback block will be triggered when the bot receives a
    # message that matches the given command regex (or an alias regex). The
    # callback block will have access to the sender and the parameter(s) (not
    # including the command itself), and should either return a String response
    # or +nil+. If a callback block returns a String response, the response will
    # be delivered to the Jabber id that issued the command.
    #
    # Examples:
    #
    #   # Say 'puts foo' or 'p foo' and 'foo' will be written to $stdout.
    #   # The bot will also respond with "'foo' written to $stdout."
    #   add_command(
    #     :syntax      => 'puts <string>',
    #     :description => 'Write something to $stdout',
    #     :regex       => /^puts\s+(.+)$/,
    #     :alias       => [ :syntax => 'p <string>', :regex => /^p\s+(.+)$/ ]
    #   ) do |sender, message|
    #     puts "#{sender} says #{message}."
    #     "'#{message}' written to $stdout."
    #   end
    #
    #   # 'puts!' is a non-responding version of 'puts', and has two aliases,
    #   # 'p!' and '!'
    #   add_command(
    #     :syntax      => 'puts! <string>',
    #     :description => 'Write something to $stdout (without response)',
    #     :regex       => /^puts!\s+(.+)$/,
    #     :alias       => [ 
    #       { :syntax => 'p! <string>', :regex => /^p!\s+(.+)$/ },
    #       { :syntax => '! <string>', :regex => /^!\s+(.+)$/ }
    #     ]
    #   ) do |sender, message|
    #     puts "#{sender} says #{message}."
    #     nil
    #   end
    #
    #  # 'rand' is a public command that produces a random number from 0 to 10
    #  add_command(
    #   :syntax      => 'rand',
    #   :description => 'Produce a random number from 0 to 10',
    #   :regex       => /^rand$/,
    #   :is_public   => true
    #  ) { rand(10).to_s }
    #
    def add_command(command, &callback)
      name = command_name(command[:syntax])

      # Add the command meta - used in the 'help' command response.
      add_command_meta(name, command)

      # Add the command spec - used for parsing incoming commands.
      add_command_spec(command, callback)

      # Add any command aliases to the command meta and spec
      unless command[:alias].nil?
        command[:alias].each { |a| add_command_alias(name, a, callback) }
      end
    end

  private

    # Add a command alias for the given original +command_name+
    def add_command_alias(command_name, alias_command, callback) #:nodoc:
      original_command = @commands[:meta][command_name]
      original_command[:syntax] << alias_command[:syntax]

      alias_name = command_name(alias_command[:syntax])

      alias_command[:is_public] = original_command[:is_public]

      add_command_meta(alias_name, original_command, true)
      add_command_spec(alias_command, callback)
    end 

    # Add a command meta
    def add_command_meta(name, command, is_alias=false) #:nodoc:
      syntax = command[:syntax]

      @commands[:meta][name] = {
        :syntax       => syntax.is_a?(Array) ? syntax : [syntax],
        :description  => command[:description],
        :is_public    => command[:is_public] || false,
        :is_alias     => is_alias
      }
    end

    # Add a command spec
    def add_command_spec(command, callback) #:nodoc:
      @commands[:spec] << {
        :regex      => command[:regex],
        :callback   => callback,
        :is_public  => command[:is_public] || false,
        :html       => command[:html] || false
      }
    end

    # Extract the command name from the given syntax
    def command_name(syntax) #:nodoc:
      if syntax.include? ' '
        syntax.sub(/^(\S+).*/, '\1')
      else
        syntax
      end
    end

end
