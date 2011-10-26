require 'xmpp4r/muc'
class TykeMuc < Jabber::MUC::SimpleMUCClient 
  # pass thru
  def initialize(stream)
    super(stream)
  end
 
  # raw send
  def say_xhtml(xhtml_contents,text=nil)
    msg = Jabber::Message.new
    msg.type = :groupchat
    html = msg.add(Jabber::XHTML::HTML.new(xhtml_contents))
    msg.body = text ? text : html.to_text
    send(msg)
  end
end
