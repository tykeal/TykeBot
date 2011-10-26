require 'json'
require 'rexml/document'

plugin.add_command(
	:syntax      => 'hot',
	:description => 'Show trending topics on twitter',
	:regex       => /^hot$/,
	:is_public   => true,
  :html        => true
) do |sender|
  begin
    p=REXML::Element.new('p')
    p.add_text("Here's what the kids are twatting about: ")
    trends=TwitterApi.new(plugin.config[:woeid]).hot.reject{|t| t["promoted_content"]}
    tweet = TwitterApi.new.search(trends[rand(trends.size)]["name"],1).first
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
    plugin.warn("error talking to twitter: %s %s",$!,$!.backtrace.join("\n"))
    "woops, I failed talking to twitter..."
  end
end

class TwitterApi
  DEFAULT_WOEID=2490383 # seattle
  URL='http://api.twitter.com/1/trends/%s.json'
  SEARCH_URL='http://search.twitter.com/search.json?q=%s&lang=en&result_type=popular&rpp=%d'
  def initialize(woeid=nil)
    @woeid=woeid||DEFAULT_WOEID
  end
  def hot
    JSON.parse(http_get(URL % @woeid).body).first["trends"]
  end
  def search(q,limit)
    JSON.parse(http_get(SEARCH_URL % [CGI.escape(q),limit]).body)["results"]
  end

end
