command do
  description "give the urban dictionary def a term :)"
  action :required=>:term, :html=>true do |term|
    begin
      if results=call_urban_dictionary(term)
        display_results(term,results)
      else
        display_no_results(term)
      end
    rescue
      error
      "Error talking to urbandictionary.com or parsing response!  Try again later..."
    end
  end
end

helper :call_urban_dictionary do |term|
  http_get("http://www.urbandictionary.com/iphone/search/define?term=#{CGI.escape(term)}",:format=>:json)
end

helper :display_results do |term,results|
  list = Array(results["list"]).compact
  case results["result_type"]
  when "no_results"
    if list.empty?
      display_no_results(term)
    else
      "#{display_no_results(term)}  Did you mean one of: #{list[0..4].map{|e| h(e["term"])}.join(", ")}?"
    end
  when "exact"
    entry = list.first
    "<a href=\"%s\"><em>%s</em></a>: %s<br/><em>example: %s</em>" % [
      entry["permalink"],
      h(term),
      h(entry["definition"]),
      entry["example"],
    ]
  else
    "Well this is embarassing .... don't know how to render result of type #{entry["result_type"]}... fix me!"
  end
end

helper :display_no_results do |term|
  "No entries found for <em>#{h(term)}</em>..."
end
