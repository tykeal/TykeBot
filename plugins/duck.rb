require 'json'

DUCK_URL = "http://api.duckduckgo.com/?q=!ducky+%s&format=json&no_redirect=1"

# We should have something better than this
def remove_invalid_markup(s)
  s.gsub("<body.*>", "").gsub("<html.*>", "").gsub("</body>", "").gsub("</html>", "").gsub("&amp;", "&").gsub("&nbsp;", " ")
end

def search(q)
  output = http_get(DUCK_URL % CGI.escape(q)).body
  json = JSON.parse(output)
  abstract = json['AbstractText']
  result = abstract ? abstract + "<br/>" : ""
  related_topics = json['RelatedTopics']
  redirect = json["Redirect"]
  summary = related_topics.collect do |topic|
  	topic['Result'] + "<br/>"
  end
  result += (redirect ? redirect + "<br/>" : "") + 
  			(summary ? summary.to_s : "")
  remove_invalid_markup(result)
end

command(:duck, 
  :required=>:q,
  :description => "Lookup info using duckduckgo.com",
  :html => true
) do |message,q|
  begin
    search(q)
  rescue
    error
    "Something went awry..."
  end
end
