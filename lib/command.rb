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

  # an exception if you want to report an error via chat message
  class CommandException < StandardError
    attr_accessor :reply, :usage
    def initialize(options={})
      super(options[:message])
      @reply=options[:reply]
      @usage=options[:usage]
    end
    def reply?
      reply
    end
  end
  
  class Action
    attr_reader :names, :syntax, :description, :callback, :required, :optional

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

    def match(text,params)
      (default? && required.size<=params.size) ||
        (names.map(&:to_s).include?(params.first) && required.size<=params.rest.size)
    end

    def args(text,params)
      params.shift if name? && names.map(&:to_s).include?(params.first)
      num = required.size + optional.size
      if params.size == 0
        [] # no params
      elsif num == 0
        [params.join(" ")] # no args, so turn all the params into 1
      else
        ((num > 1 ? params[0..(num-2)] : []) + [(params[(num-1)..-1]||[]).join(" ")])
      end.compact.reject{|p| p==""}.map(&:strip)
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
    @actions.delete_if do |existing_action|
      ((existing_action.names & new_action.names).size > 0 ||
          existing_action.default? && new_action.default?) &&
        existing_action.required.size == new_action.required.size &&
        existing_action.optional.size <= new_action.optional.size
    end
    @actions = (@actions + [new_action]).sort
    new_action
  end
  
  # matches actions in order of arity, with default ones checked last
  def match(chat_text,params,admin=nil)
    actions.select{|a| admin || a.public?}.sort.each do |a|
      if args = action_match?(a,chat_text,params)
        logger.debug("COMMAND: #{names.inspect} #{a} matched with params #{args.inspect}")
        return [a,args] # stop at first action match
      end
    end
    # no matching commands found
    return nil
  end

  def message(bot,message,args)
    a,args = match(message.body,args,message.sender.admin?)
    if a
      sender = message.sender.display
      to = sender if message.chat?
      bot.publish(:command_match,self,sender,message,args)

      begin
        if response = a.act(args, message)
          logger.debug("COMMAND: #{names.join("|")} sending response: #{response}")
          if a.html?
            atts = Sanitize::Config::RELAXED[:attributes]
            atts['p'] = ['style']
            html = Sanitize.clean(response, Sanitize::Config::RELAXED.merge({:output=>:xhtml, :attributes => atts}))
            logger.debug("COMMAND: sanitized html: #{html}")
            bot.send(:xhtml=>html,:to=>to)
          else
            bot.send(:text=>response,:to=>to)
          end
        end
      rescue CommandException => e
        bot.send(:text=>e.reply,:to=>to) if e.reply?
        raise e # pass it up
      end
    end
  end

  def <=>(other)
    self.name <=> other.name
  end

private

  # returns args if match, nil otherwise
  def action_match?(a,s,params)
    if names.map(&:to_s).include?(params.first) && a.match(s,params.rest)
      a.args(s,params.rest)
    end
  end

end
