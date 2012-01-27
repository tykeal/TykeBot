# [name, [option1, [jid1, jid2, jid3, ...]], [option2, [jid1]], ...]
active_poll = nil

command do
  description "Take Polls"
  
  action :start, :required=>:poll do |poll|
    if !active_poll
      name, *options = poll.split("\n").map(&:strip)
      active_poll = [name, *options.map{|o| [o,[]]}]
      "Poll (%s) started!  Vote by saying !poll followed by one of %s!" % [active_poll.first,option_names.map{|o| o[0..0] }.join(",")]
    else
      "Poll (%s) already started.  Please close it first!" % active_poll.first
    end
  end

  action :close do 
    if active_poll
      name = active_poll.first
      results = options.map{|o| "#{o.first} - #{o[1] ? o[1].size : 0}"}.join("\n")
      active_poll = nil        
      "Poll Results: %s\n%s" % [name,results]
    else 
      "No active poll.  Make one using poll start."
    end
  end
 
  action :optional=>:n do |message,n|
    if active_poll
      if option = options.detect{|o| o.first.match(/#{Regexp::quote(n)}/i)}
        # remove from all options
        options.each{|o| o[1].delete(message.sender.display)}
        # add to matching options
        option[1] << message.sender.display
        "#{message.sender.display} voted for #{option.first}."
      else
        "Please vote for one of the following: #{option_names.map{|o| "(#{o[0..0]} - (#{o})" }.join(", ")}"
      end
    else
      "No active poll.  Make one using poll start."
    end
  end 
end

helper :options do
  active_poll[1..-1] 
end

helper :option_names do
  options.map(&:first)
end
