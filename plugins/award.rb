# data: {"awardee":{"award":["awarder1","awarder2",...],...},...}
command do
  description "Reward/punish your fellow roomates with awards."

  action :description=>'Show your own detail award info.  Only available in MUC.' do |msg|
    if msg.room?
      who=msg.sender.nick
      display_awards_detail(who,award_data[who])
    else
      "sorry, this only works in MUC for the moment.  use award <your-nick> in the mean time."
    end
  end

  action :required=>:who, :description=>'Show award info for the given member.' do |who|
    display_awards_detail(who,award_data[who])
  end

  action :required => [:who,:award], :description=>'Assign an award to the member.' do |msg,who,award|
    from=msg.sender.display
    if bot.room.roster[who]
      data=award_data
      counter=award_counter(data,who,award)
      counter.delete(from) # prevent double voting
      counter << from
      save_awards(data)
      "Congratulations!  #{who} has been awarded the '#{award}' award by #{from}."
    else
      "#{who} is not a member of the room!  Try one of #{bot.room.roster.map{|nick,p| nick}.join(", ")}"
    end
  end

  action :list, :description=>'List all members with awards.' do |who|
    award_data.map{|awardee,awards| display_awards(awardee,awards)}.sort.join("\n")
  end

  action :revoke, :required => [:who,:award], :description=>'Take back an award you gave to a member.' do |msg,who,award|
    from=msg.sender.display
    data=award_data()
    counter=award_counter(data,who,award)
    counter.delete(from)
    save_awards(data)
    "#{from} has revoked their award of #{award} to #{who}!"
  end

end

helper :display_awards do |awardee,awards|
  "#{awardee}: " + awards.map{|award,awarders| "#{award} (L#{awarders.size})"}.join(", ")
end

helper :display_awards_detail do |awardee,awards|
  if awards
    "#{awardee}: " + awards.map{|award,awarders| "\n  #{award} (L#{awarders.size}) by #{awarders.join(", ")}"}.join('')
  else
    "#{awardee}: No awards, so sad!"
  end
end

helper :award_data do
  load_data||{}
end

helper :award_counter do |data,who,award|
  data[who]||={}
  data[who][award]||=[]
end

helper :save_awards do |data|
  data.each{|awardee,awards| awards.reject!{|award,awarders| awarders.nil? || awarders.size==0}}
  data.reject!{|awardee,awards| awards.nil? || awards.size==0}
  save_data(data)
end
