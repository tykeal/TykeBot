class TykeMessage
  attr_accessor :sender, :raw
  def initialize(bot,message)
    @bot=bot
    @raw=message
    @sender = Sender.new(@bot,@raw)
  end

  def body?
    raw.body && raw.body.to_s.size > 0
  end
  
  def delay?
    raw.first_element('delay')
  end

  def type
    raw.type
  end

  def chat?
    raw.type==:chat
  end

  def room?
    raw.type==:groupchat
  end

  def method_missing(meth,*args,&block)
    if(raw.respond_to?(meth))
       raw.send(meth,*args,&block)
    else
      super
    end
  end

  class Sender
    def initialize(bot,raw)
      @bot=bot
      @raw = raw
      @from = raw.from
    end

    def room?
      @raw.type==:groupchat
    end

    def chat?
      @raw.type==:chat
    end

    def admin?
      @bot.master?(jid)
    end

    def bot?
      room? && nick == @bot.name || chat? && jid == @bot.name
    end

    def jid
      @from.to_s.split("/").first
    end

    def resource
      @from.to_s.split("/").last
    end

    def nick
      # TODO what should we do if not room?
      resource
    end

    def display
      room? ? nick : jid
    end

    def to_s
      @from.to_s
    end
 
    def raw
      @from
    end
  end
end
