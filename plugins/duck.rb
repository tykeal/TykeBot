config :url,:default=>"http://api.duckduckgo.com/?q=!ducky+%s&format=json&no_redirect=1",:description=>'URL of the duckduckgo.com search api'

command do
  description "Lookup info using duckduckgo.com"

  action(:required=>:q,:html=>true) do |message,q|
    begin
      search(q)
    rescue
      error
      "Something went awry..."
    end
  end
end

helper :search do |q|
  json = JSON.parse(http_get(config.url % CGI.escape(q)).body)
  abstract = json['AbstractText']
  result = abstract ? abstract + "<br/>" : ""
  related_topics = json['RelatedTopics']
  redirect = json["Redirect"]
  summary = related_topics.collect do |topic|
  	topic['Result'] + "<br/>"
  end
  result += (redirect ? redirect + "<br/>" : "") + 
  			(summary ? summary.to_s : "")
end
