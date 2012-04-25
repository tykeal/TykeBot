require 'json'
require 'nokogiri'
require 'open-uri'
require "cgi"
last_woot = nil
#is_woot_off = false
woot_watchers = []

config :woot_off_check, :default=>30, :description=>'how often to query woot.com during a wootoff'

def woot()
  output =Nokogiri::HTML( http_get('http://www.woot.com/').body) rescue nil
  if(output)
    #is_woot_off = output.search("img").select{|i| i.attributes["src"].value =~ /woot-off/}.size > 0
    title = output.search("div.productDescription").search("h2").text
    price = output.search("div.productDescription").search("h3").text
    buy  = output.search("div.productDescription").search("h5 a")[0].attributes["href"]
    link = (buy && !buy.empty? && buy.value && !buy.value.empty?) ? '<a href="'+buy.value +'">Buy Now</a>': "sold out!"
    last_woot = title+" "+price+"<br/>"+link+' or <a href="http://www.woot.com">Read More</a>'
  else 
    nil
  end

end

command do
  description 'Get the current woot item'
  action(:html=>true){ woot }
end

command :wootoff do
  description 'For private chat. start/stop posting the woot off!' 

  action :start do |message|
    if message.chat?
      save_data(woot_watchers |= [message.sender.jid]) 
      "You have been added to the watch list."
    end
  end

  action :stop, :default=>true do |message|
    if message.chat?
      save_data(woot_watchers -= [message.sender.jid])
      "You have been removed from the watch list."
    end
  end

  action :list do
    woot_watchers.map(&:to_s).join("\n")
  end
end

init do
  woot_watchers=load_data||[]
  (check = Proc.new {
    past_woot=last_woot.to_s.clone
    if  woot_watchers.size>0
      current =  woot() 
      last_woot = current if current
      if(past_woot!=last_woot && last_woot)
        send :to=>woot_watchers.uniq, :xhtml=>("New Woot!<br/>"+last_woot) rescue error
      end
    end
    timer(config.woot_off_check,&check)
  }).call()
end

