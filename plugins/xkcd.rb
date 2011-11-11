require 'json'
require 'nokogiri'
require 'open-uri'
require "cgi"

def format_url(url,text=nil)
  '<a href="%s">%s</a>' % [url, text||url]
end

def search(q)
  doc = Nokogiri::HTML(open( "http://www.google.com/cse?cx=012652707207066138651%3Azudjtuwe28q&ie=UTF-8&q=#{CGI.escape(q)}&sa=Search&siteurl=xkcd.com%2F#gsc.tab=0&gsc.q=dead%20pixel&gsc.page=1"))
  urls = doc.xpath('//a').map{ |link| link.attributes["href"].to_s}.select{|u| u.match(/xkcd\.com\/\d+/)}.uniq
  urls.first ? urls.map{|url| format_url(url)}.join("<br/>\n") : "xkcd hasn't covered that subject. Are you sure you exist?"
end

command(:xkcd, 
  :required=>:q,
  :description => "Find an XKCD strip for a subject",
  :html => true
) do |message,q|
  search(q)
end
