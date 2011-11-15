class TykeMessage
  attr :message
  def initialize(message)
    @message=message
  end

  def method_missing(meth,*args,&block)
    if(@message.respond_to?(meth))
       @message.send(meth,*args,&block)
    else
      super
    end
  end
end
