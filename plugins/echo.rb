command do
  description "echo a string"
  action :required=>:s do |m,s|
    bot.send :text=>s if m.chat?
    s
  end
end
