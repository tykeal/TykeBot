require "uri"
config :woeid, :default=>2490383, :description=>''
config :error_msg, :default=>'woops, I failed talking to twitter...', :description=>'error message to give when twitter error'

command do
  description 'Show trending tweets/topics on twitter'

  action :trends, :default=>true, :html=>true, :description=>'Show trending tweets' do
    handle_errors do
      trends=hot(config.woeid)
      "<p>Here's what the kids are tweeting about: " +
        "#{render_tweet(search(trends.sample["name"]))}" +
        "<br/><br/>#{trends.map{|t|render_topic(t)}.join(", ")}</p>"
    end
  end

  action :search, :required=>:topic, :default=>true, :html=>true, :description=>'Search twitter' do |message,topic|
    handle_errors do
      render_tweet(search(topic))
    end
  end

end

helper :handle_errors do |&block|
  begin
    block.call
  rescue
    error
    config.error_msg
  end
end

helper :hot do |woeid|
  trends_url="http://api.twitter.com/1/trends/#{woeid}.json"
  JSON.parse(http_get(trends_url).body).first["trends"].reject{|t| t["promoted_content"]}
end

helper :search do |q|
  search_url='http://search.twitter.com/search.json?q=%s&lang=en&result_type=popular&rpp=1'
  JSON.parse(http_get(search_url % CGI.escape(q)).body)["results"].first
end

helper :link_up_tweets do |tweet|
  tweet.gsub!(/(@\w+)/) do
    name = $1
    "<a href='http://twitter.com/#{name.sub("@","")}' target='_blank'>#{name}</a>"
  end
  tweet.gsub!(/(#\w+)/) do
    name = $1
    "<a href='http://twitter.com/#!/search?q=#{URI.escape(name)}' target='_blank'>#{name}</a>"
  end
  tweet 
end

helper :render_tweet do |tweet|
  tweet ? "<a href='http://twitter.com/%s' target='_blank'>@%s</a> %s" % [tweet["from_user"],tweet["from_user"],link_up_tweets(tweet["text"])] : 'no tweets found...'
end

helper :render_topic do |t|
  '<a href="%s">%s</a>' % [t["url"],h(t["name"])]
end
