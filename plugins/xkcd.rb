require 'json'
require 'nokogiri'
require 'open-uri'
require "cgi"

def format_url(url,text=nil)
  '<a href="%s">%s</a>' % [url, text||url]
end

def search(q)
  doc = Nokogiri::HTML(open('http://www.google.com/search?q=site:m.xkcd.com+'+CGI.escape(q)))
  urls = doc.xpath('//cite').map{ |link| link.text}.select{|u| u.match(/m\.xkcd\.com\/\d+/)}
  url = urls[rand(urls.size)] 
  url ? format_url("http://"+url,"xkcd on "+q) : "xkcd hasn't covered that subject. Are you sure you exist?"
end

command(:xkcd, 
  :required=>:q,
  :description => "Find an XKCD strip for a subject",
  :html => true
) do |message,q|
  search(q)
end
