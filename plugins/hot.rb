require 'json'
require 'rexml/document'

def hot(woeid)
  trends_url="http://api.twitter.com/1/trends/#{config[:woeid]||2490383}.json"
  JSON.parse(http_get(trends_url).body).first["trends"]
end
def search(q,limit)
  search_url='http://search.twitter.com/search.json?q=%s&lang=en&result_type=popular&rpp=%d'
  JSON.parse(http_get(search_url % [CGI.escape(q),limit]).body)["results"]
end

command(:hot,
	:description => 'Show trending topics on twitter',
  :html        => true
) do |sender|
  begin
    p=REXML::Element.new('p')
    p.add_text("Here's what the kids are twatting about: ")
    trends=hot(config[:woeid]||2490383).reject{|t| t["promoted_content"]}
    tweet=search(trends.sample["name"],1).first
    if tweet
      p.add_text("@")
      p.add_text(tweet["from_user"])
      p.add_text(" ")
      p.add_text(tweet["text"])
      p.add_element('br')
    end
    trends.each_with_index do |t,i|  
      a=p.add_element('a')
      a.text=t["name"]
      a.add_attribute("href",t["url"])
      p.add_text(', ') unless i==trends.size-1
    end
    p.to_s
  rescue
    error("problem talking to twitter",$!)
    "woops, I failed talking to twitter..."
  end
end

