forcedevent = nil

def get_fortune
  `/usr/bin/fortune`
end

command(:fortune,
  :description => 'get a fortune'
) { get_fortune() }

subscribe :give_fortune do |options|
  fortune = get_fortune()
  if !options[:fortune_prefix].nil?
    fortune = options[:fortune_prefix] + fortune
  end
  bot.send(:text=>fortune)
end
