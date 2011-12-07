plugin_require('wolfram.rb')

config :api_key, :description=>'wolfram alpha api key'

command do
  aliases :whats
  description 'ask wolfram alpha'

  action :required=>:query do |message,query|
    begin 
      results = WolframApi.new(config.api_key).query(query)
      if results && results.size > 0
        results.map{|r| r.join(": ")}.join("\n")  
      else
        "Wolfram didn't know anything about that..."
      end
    rescue
      error
      "Sorry, I had an error talking to wolfram or parsing the response..."
    end
  end
end
