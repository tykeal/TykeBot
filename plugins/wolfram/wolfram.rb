# allow access to the worlfram alpha api
require 'cgi'
require 'rexml/document'

class WolframApi

  QUERY_URL="http://api.wolframalpha.com/v2/query?appid=%s&input=%s&format=plaintext"

  def initialize(api_key)
    @api_key = api_key
  end

  # returns array of [title, text] pairs
  def query(s)
    if @api_key.nil?
      [['ERROR',"Wolfram Alpha key has not been configured.  Please add a wolframkey config option"]]
    else
      parse(do_query(s))
    end
  end

  def parse(xml)
    doc = REXML::Document.new(xml) 
    results = []
    doc.elements.each('queryresult/pod') do |pod|
      title = pod.attributes['title']
      pod.elements.each('subpod/plaintext') do |txt|
        results << [title,txt.text]
      end
    end
    results
  end
  
private

  def do_query(s)
    http_get(QUERY_URL % [@api_key,CGI.escape(s)]).body
  end

end
