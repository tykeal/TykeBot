class Command
  attr_reader :name, :plugin, :syntax, :description
  attr_accessor :enabled

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
    # callback block will have access to the raw message and the parameter(s) (not
    # including the command itself), and should either return a String response
    # or +nil+. If a callback block returns a String response, the response will
    # be delivered to the Jabber id that issued the command.
    #
    # Examples:
    #
    #   # Say 'puts foo' or 'p foo' and 'foo' will be written to $stdout.
    #   # The bot will also respond with "'foo' written to $stdout."
    #   Command.new(
    #     :syntax      => 'puts <string>',
    #     :description => 'Write something to $stdout',
    #     :regex       => /^puts\s+(.+)$/,
    #     :alias       => [ :syntax => 'p <string>', :regex => /^p\s+(.+)$/ ]
    #   ) do |message, msg|
    #     puts "#{bot.sender(message)} says #{msg}."
    #     "'#{msg}' written to $stdout."
    #   end
    #
    #   # 'puts!' is a non-responding version of 'puts', and has two aliases,
    #   # 'p!' and '!'
    #   Command.new(
    #     :syntax      => 'puts! <string>',
    #     :description => 'Write something to $stdout (without response)',
    #     :regex       => /^puts!\s+(.+)$/,
    #     :alias       => [ 
    #       { :syntax => 'p! <string>', :regex => /^p!\s+(.+)$/ },
    #       { :syntax => '! <string>', :regex => /^!\s+(.+)$/ }
    #     ]
    #   ) do |message, msg|
    #     puts "#{bot.sender(message)} says #{msg}."
    #     nil
    #   end
    #
    #  # 'rand' is a public command that produces a random number from 0 to 10
    #  Command.new(
    #   :syntax      => 'rand',
    #   :description => 'Produce a random number from 0 to 10',
    #   :regex       => /^rand$/,
    #   :is_public   => true
    #  ) { rand(10).to_s }
    #
  def initialize(options,&callback)
    [:regex,:syntax].each do |key|
      raise ArgumentError, "#{key} is required" unless options[key]
    end
    @syntax = Array(options[:syntax])
    @name = options[:name] || command_name(@syntax.first)
    @regex = Array(options[:regex])
    # aliases
    Array(options[:alias]).each do |a| 
      @regex << a[:regex] 
      @syntax << a[:syntax]
    end
    @is_public = options.has_key?(:is_public) ? options[:is_public] : true
    @html = options[:html]
    @enabled = options.has_key?(:enabled) ? options[:enabled] : true
    @plugin = options[:plugin]
    @callback = callback
    @description = options[:description] 
  end

  def public? ; @is_public ; end
  def enabled? ; @enabled ; end

  def message(bot,message)
    if m = @regex.map{|r| message.body.match(r)}.compact.first
      sender = bot.sender(message)
      bot.publish(:command_match,self,sender,message,m.captures)
      if response = @callback.call(message,*m.captures) 
        to = sender unless bot.groupchat?(message) 
        if @html
          html = Sanitize.clean(response, Sanitize::Config::RELAXED.merge(:output=>:xhtml))
          debug("sanitized html: #{html}")
          bot.send(:xhtml=>html,:to=>to)
        else
          bot.send(:text=>response,:to=>to)
        end
      end
    end
  end

  def <=>(other)
    self.name <=> other.name
  end

  private

    # Extract the command name from the given syntax
    def command_name(syntax) #:nodoc:
      if syntax.include? ' '
        syntax.sub(/^(\S+).*/, '\1')
      else
        syntax
      end
    end

end
