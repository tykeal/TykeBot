require 'json'

def hot(woeid)
  trends_url="http://api.twitter.com/1/trends/#{config[:woeid]||2490383}.json"
  JSON.parse(http_get(trends_url).body).first["trends"].reject{|t| t["promoted_content"]}
end
def search(q)
  search_url='http://search.twitter.com/search.json?q=%s&lang=en&result_type=popular&rpp=1'
  JSON.parse(http_get(search_url % CGI.escape(q)).body)["results"].first
end
def render_tweet(tweet)
  tweet ? "@%s %s" % [tweet["from_user"],tweet["text"]] : 'no tweets found...'
end
def render_topic(t)
  '<a href="%s">%s</a>' % [t["url"],h(t["name"])]
end

command(:hot,
  :optional=>:topic,
	:description => 'Show trending topics on twitter',
  :html        => true
) do |message,topic|
  begin
    if topic
      render_tweet(search(topic))
    else
      trends=hot(config[:woeid]||2490383)
      "<p>Here's what the kids are tweeting about: " +
        "#{render_tweet(search(trends.sample["name"]))}" +
        "<br/><br/>#{trends.map{|t|render_topic(t)}.join(", ")}</p>"
    end
  rescue
    error("problem talking to twitter",$!)
    "woops, I failed talking to twitter..."
  end
end

