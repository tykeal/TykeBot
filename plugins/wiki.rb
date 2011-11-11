require 'json'

WIKI_URL = "http://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=%s&format=json&limit=5"

def wiki_search(q)
  output = http_get(WIKI_URL % CGI.escape(q)).body
  query = JSON.parse(output)["query"]
  search = query["search"] if query
  item = search.first if search
  if item then
    result = "<li><strong>" + item["title"] + "</strong> - " + item["snippet"] + "</li>\n"
    ("<ul>" + result + "</ul>").gsub("<span class='searchmatch'>","<em>").gsub("</span>", "</em>")
  end
end

command(:wiki, 
  :required=>:q,
  :description => "Find wikipedia summaries for a subject",
  :html => true
) do |message,q|
  wiki_search(q)
end
