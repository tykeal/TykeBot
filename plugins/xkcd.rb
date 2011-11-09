require 'json'

QUERY_URL = "http://api.duckduckgo.com/?q=!ducky+xkcd+%s&format=json&no_redirect=1"

def search(q)
  q = q.gsub(" ", "+")
  output = http_get(QUERY_URL % q).body
  JSON.parse(output)["Redirect"].first
end

command(:xkcd, 
  :required=>:q
  :description => "Find an XKCD strip for a subject",
  :html => true
)
do |q|
    search_output = search(q)
	'<a href="%s">%s</a>' % [search_output, search_output]
end
