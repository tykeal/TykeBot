command do
  description 'respond with lmgtfy link'
  action :required=>:q do |message,q|
    "http://lmgtfy.com/?q="+CGI.escape(q)
  end
end
