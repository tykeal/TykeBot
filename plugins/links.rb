require 'uri'
file=data_file('links.json')
format=config[:date_format]||'%Y-%d-%m %I:%M%p'
limit=(config[:limit]||20).to_i

command(:links,
  :optional=>[:n,:sender],
  :description=>'show links from the room',
  :html=>true
) do |message,n,sender|
  n = (n || 5).to_i
  n = limit if n > limit
  lines = []
  open(file) do |f| 
    f.reverse_readline do |line| 
      info = JSON.parse(line) 
      lines << info if !sender || info['from'].strip == sender.strip
      lines.size<n 
    end
  end if File.exist?(file)
  lines.reverse.map{|info| 
    '%s %s <a href="%s">%s</a>' % [
      h(Time.at(info['time']).strftime(format)),
      h(info['from']),
      h(info['url']),
      h(URI.parse(info['url']).host)
    ]
  }.join("\n<br/>")
end

subscribe(:firehose) do |bot,message|
  URI.extract(message.body, ['http', 'https']).each do |url|
    open(file,"a"){|f| f.puts JSON.generate({
      :url=>url,
      :from=>bot.sender(message),
      :time=>Time.now.to_i
    })}
  end unless bot.sender(message) == bot.config[:name]
end
