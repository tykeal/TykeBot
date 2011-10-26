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
  def initialize(woeid)
    @woeid=woeid||DEFAULT_WOEID
  end
  def hot
    JSON.parse(http_get(URL % @woeid).body).first["trends"]
  end
end
