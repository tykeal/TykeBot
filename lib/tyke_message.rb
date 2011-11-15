class TykeMessage
  attr :raw_message
  def initialize(message)
    @raw_message=message
  end

  def type
    @raw_message.type
  end

  def group_chat?
    @raw_message.type==:groupchat
  end

  def method_missing(meth,*args,&block)
    if(@raw_message.respond_to?(meth))
       @raw_message.send(meth,*args,&block)
    else
      super
    end
  end
end
