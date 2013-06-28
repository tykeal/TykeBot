stats={:people=>{}}
command do
  description "show stats for the bot"

  action :show, :default=>true do |message|
    bot.commands(!message.sender.admin?).sort.map{|cmd| "%s=%d" % [cmd.name,stats[:commands][cmd.name]||0]}.join("\n")
  end

  action :people do |message|
    # set everybody in the room currently as last seen now...
    bot.room.roster.keys.each {|nick| update_person(nick,:save=>false)}
    save_data(stats)


    # format report
    now = Time.now
    logger.debug("raw stats dump: #{stats.inspect}")
    logger.debug("stats report now=#{now.to_i}")
    stats[:people].map do |p,s|
      "%s: %d posts, last seen %s, last heard %s" % [
        p,
        s[:count]||0,
        time_diff_in_natural_language(now,Time.at(s[:last]||0)) || "now",
        time_diff_in_natural_language(now,Time.at(s[:talk]||0)) || "now"
      ]
    end.join("\n")
  end

  action :clear do |message|
    stats = {:commands=>{},:people=>{},:version=>2}
    save_data(stats)
  end

end

on :welcome do |msg|
  update_person(msg.sender.nick,{})
end

on :leave do |msg|
  update_person(msg.sender.nick,{})
end

on :firehose do |msg|
  update_person(msg.sender.nick,:talk=>true) if msg.room?
end
  
on :command_match do |cmd,*params|
  stats[:commands][cmd.name] ||= 0
  stats[:commands][cmd.name] += 1
  save_data(stats)
end

init do 
  # migrations
  stats = load_data||{}
  case stats[:version]
  when nil
    stats = {:commands => stats||{}, :people => {}, :version=>2}
    save_data(stats)
  end
end

helper :update_person do |nick,options|
  now = Time.now.to_i
  options[:save] = options.has_key?(:save) ? options[:save] : true # default true
  p = stats[:people][nick] ||= {}
  p[:last] = now
  if options[:talk]
    p[:talk] = now
    p[:count] ||= 0
    p[:count] += 1
  end
  save_data(stats) if options[:save]
end
