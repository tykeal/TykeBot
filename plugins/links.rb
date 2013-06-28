require 'open-uri'

config :limit, :default=>1024, :description=>'max links to return one-on-one'
config :muc_limit, :default=>20, :description=>'max links to return from the room if MUC'
config :date_format, :default=>'%Y-%d-%m %I:%M%p', :description=>'Date format string to use for links, see Time#strftime'

command do
  description 'show links from the room' 

  action :filter, :required=>:sender, :optional=>:n, :html=>true do |message,sender,n|
    display(
      filter_and_limit(message,n) {|info|
        info['from'].strip.match(Regexp.new(sender))})
  end

  action :latest, :optional=>:n, :default=>true, :html=>true do |message,n|
    display(filter_and_limit(message,n))
  end
end

file=data_file('links.json')
helper :links do |max,&block|
  returning([]) do |lines|
    open(file) do |f| 
      f.reverse_readline do |line|
        json = JSON.parse(line)  
        lines << json if !block or block.call(json)
        lines.size<max
      end
    end if File.exists?(file)
  end
end

helper :filter_and_limit do |message,n,&block|
  limit=message.room? ? config.muc_limit : config.limit
  links bound(n,:default=>5,:max=>limit), &block
end

helper :display do |lines|
  lines.reverse.map{|info| 
    '%s %s <a href="%s">%s</a>' % [
      h(Time.at(info['time']).strftime(config.date_format)),
      h(info['from']),
      h(info['url']),
      h(URI.parse(info['url']).host)
    ]
  }.join("\n<br/>")
end

on :firehose do |message|
  if message.body?
    URI.extract(message.body, ['http', 'https']).each do |url|
      open(file,"a"){|f| f.puts JSON.generate({
        :url=>url,
        :from=>message.sender.display,
        :time=>Time.now.to_i
      })}
      open(url).read =~ /<title>(.*?)<\/title>/ && bot.send(:text => "Title for #{url} -- #{$1}") rescue nil
    end unless message.sender.bot?
  end
end
