require 'json'
require 'nokogiri'
require 'open-uri'
require "cgi"

command do
  description "Find an XKCD strip for a subject"

  action :required=>:q, :html=>true do |q|
    search(q)
  end
end

helper :search do |q|
  doc = Nokogiri::HTML(open("http://www.google.com/cse?cx=012652707207066138651:zudjtuwe28q&ie=UTF-8&q=#{CGI.escape(q)}&sa=Search&siteurl=xkcd.com/&nojs=1"))
  urls = doc.xpath('//a').map{ |link| link.attributes["href"].to_s}.select{|u| u.match(/xkcd\.com\/\d+/)}.uniq
  urls.first ? urls.map{|url| format_url(url,nil)}.join("\n<br/>") : "xkcd hasn't covered that subject. Are you sure you exist?"
end

helper :format_url do |url,text|
  '<a href="%s">%s</a>' % [url, h(text||url)]
end

