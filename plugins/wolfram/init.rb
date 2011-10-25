plugin.require('wolfram.rb')

plugin.add_command(
  :syntax => 'whats <query>',
  :description => 'ask wolfram alpha',
	:regex       => /^whats\s+(.+)$/,
	:is_public   => true
) do |sender,query| 
  begin 
    results = WolframApi.new(plugin.config[:api_key]).query(query)
    if results && results.size > 0
      results.map{|r| r.join(": ")}.join("\n")  
    else
      "Wolfram didn't know anything about that..."
    end
  rescue
    puts "ERROR: #{$!} #{$!.backtrace.join("\n")}"
    "Sorry, I had an error talking to wolfram or parsing the response..."
  end
end

