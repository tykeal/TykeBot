require 'json'
require 'nokogiri'
require 'open-uri'
require "cgi"
last_check= Time.now
last_woot = nil
is_woot_off=false
def woot()
  output =Nokogiri::HTML( http_get('http://www.woot.com/').body)
  is_woot_off = output.search("img").select{|i| i.attributes["src"].value =~ /woot-off/}.size > 0
  last_check=Time.now
  title = output.search("div.productDescription").search("h2").text
  price = output.search("div.productDescription").search("h3").text
  link = output.search("div.productDescription").search("h5 a")[0].attributes["href"].value
  last_woot = title+" "+price+"\n"+link
end

command(:woot,:description => 'Get the current woot item') { woot }

=begin

on :join do |bot|
  timer(2) { started = true }
end

on :welcome do |bot,message|
  if (started && rand(config[:random]) < 1)
    send(:text => fortune("Welcome %s! Here have a fortune:\n" % bot.sender(message)))
  end
end

on :firehose do |bot,message|
  last_active = Time.now if started && bot.sender(message) != bot.config[:name]
end

init do
  # just give our random welcome fortune a small chance
  # can be set in config yaml
  config[:random] ||= 3

  # number of seconds to wait between messages before spewing a fotune
  config[:timer_push] ||= 5400 # 90 minutes
  last_sent = 0

  (check = Proc.new { 
    if last_sent.to_i < last_active.to_i && Time.now-last_active >= config[:timer_push]
      send :text=>fortune("It's been quiet too long.  I think we need a fortune to liven things up!\n\n") rescue error
      last_sent = Time.now
    end
    timer(600, &check)
  }).call
end

=end
