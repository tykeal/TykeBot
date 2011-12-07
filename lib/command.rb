# command object
#
# command :foo do |cmd|
#   cmd.action do |msg|
#     # impl, block value is used for response
#     # ...
#   end
# end
class Command
  attr_reader :plugin
  attr_accessor :enabled, :description, :actions, :names
  
  class Action
    attr_reader :names, :syntax, :regex, :description, :callback, :required, :optional

    # Examples:
    def initialize(options={},&callback)
      @names = Array(options[:name])
      @is_public = options.has_key?(:is_public) ? options[:is_public] : true
      @enabled = options.has_key?(:enabled) ? options[:enabled] : true
      @html = options[:html]
      @callback = callback
      @description = options[:description]
      @required = Array(options[:required])
      @optional = Array(options[:optional])
      @default = options[:default]
      @regex = options[:regex] # raw/advanced
    end

    def name; @names.first ; end
    def name?; !@names.empty?; end
    def public? ; @is_public ; end
    def html? ; @html; end
    def enabled? ; @enabled ; end
    def default? ; @default || @names.empty?; end

    def to_s
      action = names.join('|')
      action = "(#{action})" if names.size > 1
      action = "[#{action}]" if name? && default?
      "#{action}#{required.map{|r|" <#{r}>"}.join}#{optional.map{|o| " [<#{o}>]"}.join}"
    end

    # TODO: support quoted and getopt -s --long arguments!
    # /(\s+.*?)$/                    # no name: captures start at 0
    # /(\s+(name))?(\s+.*?)$/        # default: captures start at 1
    # /(\s+(name1|name2|...))?\s*$/  # default, aliased: captures start at 1
    def regex
      params = "#{required.map{'\s+(.*?)'}.join}#{optional.map{'(\s+.*?)?'}.join}"
      action = self.names.map{|name| Regexp::quote(name.to_s)}.join("|")
      action = "(\\s+(#{action}))" if name?
      action = action + "?" if default? && name?
      Regexp.new("#{action}#{params}")
    end
    
    def args(match,first=0,last=-1)
      first += (name? ? 2 : 0)
      match.captures[first..last].map{|s| s ? s.strip : nil}
    end

    def act(args,message)
      # add in the message as the first arg if block is expecting it
      if @callback.arity == required.size + optional.size + 1
        logger.debug("ACTION: calling with message + args!")
        @callback.call(message,*args)
      else
        logger.debug("ACTION: calling with no message, just args!")
        @callback.call(*args)
      end
    end

    # non-default < default, higher required < lower, higher optional < lower
    def <=>(other)
      [self.default? ? 1 : 0, self.name? ? 0 : 1, -self.required.size, -self.optional.size] <=>
        [other.default? ? 1 : 0, other.name? ? 0 : 1, -other.required.size, -other.optional.size]
    end
 
    def masks?(other)
      # share a name and same number of required params
      (self.names & other.names).size > 0 && 
        (self.required.size == other.required.size || 
        (self.required.size+self.optional.size) == (other.required.size+other.optional.size))
    end

  end

  def initialize(options,&block)
    @description = options[:description] 
    @html = options[:html] 
    @actions = []
    @names = Array(options[:name]).map(&:to_s)
    @is_public = options.has_key?(:is_public) ? options[:is_public] : true
    @enabled = options.has_key?(:enabled) ? options[:enabled] : true
    yield(self) if block
  end

  def public? ; @is_public ; end
  def enabled? ; @enabled ; end
  def name; @names.first; end
  
  def aliases(*args)
    @names |= args.map(&:to_s)
  end

  # add an action to this command
  # you can have override action names... aka diff actions with same name but diff arity
  def action(options,&callback)
    new_action = Action===options ? options : Action.new(options,&callback)
    # replace any with (shared name/alias or both default) + same arity
    actions.delete_if do |existing_action|
      ((existing_action.names & new_action.names).size > 0 ||
          existing_action.default? && new_action.default?) &&
        existing_action.required.size == new_action.required.size &&
        existing_action.optional.size <= new_action.optional.size
    end
    @actions = (@actions + [new_action]).sort
    new_action
  end
  
  # matches actions in order of arity, with default ones checked last
  def match(chat_text,master=nil)
    actions.select{|a| master || a.public?}.sort.each do |a|
      logger.debug("COMMAND: #{names.inspect} #{a} #{a.regex.inspect}")
      if params = action_match?(a,chat_text)
        logger.debug("COMMAND: #{names.inspect} #{a} matched with params #{params.inspect}")
        return [a,params] # stop at first action match
      end
    end
    # no matching commands found
    return nil
  end

  def message(bot,message)
    a,args = match(message.body,bot.master?(message))
    if a
      sender = bot.sender(message)
      bot.publish(:command_match,self,sender,message,args)
      if response = a.act(args, message)
        logger.debug("COMMAND: #{names.join("|")} sending response: #{response}")
        to = sender unless message.group_chat?
        if a.html?
          html = Sanitize.clean(response, Sanitize::Config::RELAXED.merge(:output=>:xhtml))
          logger.debug("COMMAND: sanitized html: #{html}")
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

  # returns args if match, nil otherwise
  def action_match?(a,s)
    names.each do |name|
      # TODO: allow mid chat matching
      if match = s.match(regex(name,a))
        return a.args(match)
      end
    end
    return nil
  end

  def regex(name,a)
    base = "^#{Regexp::quote(name.to_s)}"
    Regexp.new "#{base}#{a.regex.source}\\s*$"
  end

end
