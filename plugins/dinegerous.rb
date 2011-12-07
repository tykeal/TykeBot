config :url, :default=>"http://www.dinegerous.com/search/", :description=>'URL of dingerous search api'
command do
  description 'Lookup health score on dinegerous.com'

  action :required=>:q, :optional=>:n do |message,q,n|
    limit = bound( n, :min=>1, :max=>message.group_chat? ? 2 : 5)
    results = JSON.parse(http_get(config.url+CGI.escape(q)+"?limit=#{limit}").body)
    logger.debug("DINEGEROUS: results: #{results.inspect} limit: #{limit}")
    if results && !results.empty?
      results.map{|json|
        "#{json["name"]}\n#{json["address"]}\nScore:#{json["inspection_score"]}\n"}.join
    else
      "No dinegerous.com info for #{q}."
    end
  end
end
