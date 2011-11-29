def data
 load_data || [] 
end

command(:quip,
  :optional=>:list,
  :alias=>:quote,
  :description => 'give a quip / quote'
) do |message, list|
  quips = data
  if !quips.empty?
    if list
      "I know the following quotes:\n" + quips.join("\n")
    else
      quips.sample
    end
  else
    "I don't currently know any quips, why don't you tell me some?"
  end
end

command('add quip',
  :required=>:quip,
  :alias=>'add quote',
  :description => 'add a quip / quote'
) do |message, quip|
  quips = data
  save_data(quips << quip.strip) unless quips.include?(quip.strip)
end

command('delete quip',
  :required=>:quip,
  :alias=>['del quip', 'del quote', 'delete quote'],
  :description => 'delete a quip / quote'
) do |message, quip|
  quips = data
  save_data(quips) if quips.delete(quip.strip) 
end
