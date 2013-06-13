require "uri"
require "twitter"
config :woeid, :default=>2490383, :description=>''
config :consumer_key, :description=>'Twitter application API key'
config :consumer_secret, :description=>'Twitter Application API secret'
config :access_token, :description=>'Twitter OAuth2 API token'
config :access_token_secret, :description=>'Twitter OAuth2 API token secret'
config :error_msg, :default=>'woops, I failed talking to twitter...', :description=>'error message to give when twitter error'

twitter = Twitter::Client.new(
  :consumer_key => config.consumer_key,
  :consumer_secret => config.consumer_secret,
  :oauth_token => config.access_token,
  :oauth_token_secret => config.access_token_secret
)

command do
  description 'Show trending tweets/topics on twitter'

  action :trends, :default=>true, :html=>true, :description=>'Show trending tweets' do
    handle_errors do
      trends=hot(config.woeid)
      "<p>Here's what the kids are tweeting about: " +
        "#{render_tweet(search(trends.sample[:name]))}" +
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
  twitter.trends(woeid)
end

helper :search do |q|
  twitter.search(q, :count => 1)
end

helper :link_up_tweets do |tweet|
  tweet = tweet.scan(/[[:print:]]/).join
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
  if tweet.attrs[:statuses].count >= 1
    status = tweet.attrs[:statuses][0]
    "<a href='http://twitter.com/%s' target='_blank'>@%s</a> %s" % [status[:user][:screen_name],status[:user][:screen_name],link_up_tweets(status[:text])]
  else
    'no tweets found...'
  end
end

helper :render_topic do |t|
  '<a href="%s">%s</a>' % [t[:url],t[:name]]
end
