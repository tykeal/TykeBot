command(:lmgtfy, 
  :required=>:q,
  :description => "lmgtfy link "
) do |message,q|
"http://lmgtfy.com/?q="+CGI.escape(q)
end
