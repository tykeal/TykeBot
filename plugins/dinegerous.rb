require 'json'

WIKI_URL = "http://www.dinegerous.com/search/"

def dinegerous_search(q,limit)
  output = http_get(WIKI_URL+CGI.escape(q)+"?limit=#{limit}").body
  jsons = JSON.parse(output)

  jsons.map{|json|
    s="#{json["name"]}\n#{json["address"]}\nScore:#{json["inspection_score"]}\n"
  }.join
end

command(:dinegerous, 
  :required=>:q,
  :optional=>[:n],
  :description => "No"
) do |message,q,n|
  if(message)
    dinegerous_search(q,[2,(5||n)].min)
  else
    dinegerous_search(q,(n||5))
  end
end
