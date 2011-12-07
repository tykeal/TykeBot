config :url, :default=>"http://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=%s&format=json&limit=5", :description=>'search url with %s for query string'

command do
  description "Find wikipedia summaries for a subject"

  action :required=>:q, :html=>true do |message,q|
    if results = wiki_search(q)
      response = results[0..0].map{|item|
        "<li><strong>#{item["title"]}</strong> - #{item["snippet"]}</li>\n".
          gsub("<span class='searchmatch'>","<em>").gsub("</span>", "</em>")}
      "<ul>#{response}</ul>"
    end
  end
end

helper :wiki_search do |q|
  output = http_get(config.url % CGI.escape(q)).body
  query = JSON.parse(output)["query"]
  query["search"] if query
end

