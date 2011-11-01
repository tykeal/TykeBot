plugin_require('wolfram.rb')

command(:whats,
  :required    => :query,
  :description => 'ask wolfram alpha'
) do |sender,query| 
  begin 
    results = WolframApi.new(config[:api_key]).query(query)
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

