require 'json'
require 'nokogiri'
require 'open-uri'
require "cgi"
last_woot = nil
is_woot_off = false
woot_watchers = []

def woot()
  output =Nokogiri::HTML( http_get('http://www.woot.com/').body) rescue nil
  if(output)
    is_woot_off = output.search("img").select{|i| i.attributes["src"].value =~ /woot-off/}.size > 0
    title = output.search("div.productDescription").search("h2").text
    price = output.search("div.productDescription").search("h3").text
    link = output.search("div.productDescription").search("h5 a")[0].attributes["href"] ? output.search("div.productDescription").search("h5 a")[0].attributes["href"].value : "sold out!"
    last_woot = title+" "+price+"\n"+"Buy Now: "+link
  else 
    nil
  end

end

command(:woot,:description => 'Get the current woot item') { woot }

command(:wootoff,:required=>[:state],:description => 'For private chat. start/stop posting the woot off!') {|message,state| 
  if !message.group_chat? && state.strip!= "list"
    sender = message.from.to_s.split("/").first
    state.strip=="start" ? woot_watchers.push(sender)  :  woot_watchers.delete(sender) 
    woot_watchers.uniq!
    save_data(woot_watchers)
    "You have been #{state.strip=="start" ? 'added to':'removed from'} the watch list"
  elsif(state.strip=="list")
    woot_watchers.map(&:to_s).join("\n")
  end
}

init do
  woot_watchers=load_data||[]
  (check = Proc.new {
    past_woot=last_woot.to_s.clone
    if  woot_watchers.size>0
      current =  woot() 
      last_woot = current if current
      if(past_woot!=last_woot)
        send :to=>woot_watchers.uniq, :text=>("New Woot!\n"+last_woot) rescue error
      end
    end
    timer(config[:woot_off_check]||30,&check)
  }).call()
end
