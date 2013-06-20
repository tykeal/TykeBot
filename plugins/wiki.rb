config :url, :default=>"http://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=%s&format=json&srlimit=5", :description=>'search url with %s for query string'

command do
  description "Find wikipedia summaries for a subject"

  action :required=>:q, :html=>true do |message,q|
    if results = wiki_search(q)
      response = results.map{|item|
        "<a href='http://en.wikipedia.org/wiki/#{URI.escape(item["title"])}'><strong>#{item["title"]}</strong></a> - #{item["snippet"]}><br/>".
          gsub("<span class='searchmatch'>","<em>").gsub("</span>", "</em>")}
      "#{response}"
    end
  end
end

helper :wiki_search do |q|
  output = http_get(config.url % CGI.escape(q)).body
  query = JSON.parse(output)["query"]
  query["search"] if query
end

