command(:lmgtfy, 
  :required=>:q,
  :description => "lmgtfy link "
) do |message,q|
"http://lmgtfy.com/?q="+q.gsub(/\s/,"+")
end
