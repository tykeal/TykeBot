require 'json'

QUERY_URL = "http://api.duckduckgo.com/?q=!ducky+site:m.xkcd.com+%s&format=json&no_redirect=1"

def xkcd_format_url(url)
  '<a href="%s">%s</a>' % [url, url]
end

def search(q)
  output = http_get(QUERY_URL % CGI.escape(q)).body
  url = JSON.parse(output)["Redirect"].first
  /http[s]*:\/\/m.xkcd.com\/[0-9]+/.match(url) ? format(url) : "xkcd hasn't covered that subject. Are you sure you exist?"
end

command(:xkcd, 
  :required=>:q,
  :description => "Find an XKCD strip for a subject",
  :html => true
) do |message,q|
  search(q)
end
