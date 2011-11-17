def data
 load_data || [] 
end

command(:lunch,
  :optional=>:list,
  :description => 'get a lunch suggestion or list all locations currently known'
) do |message, list|
  locations = data
  if !locations.empty?
    if list
      "I know the following locations:\n" + locations.join("\n")
    else
      "How about " + locations.sample + "?"
    end
  else
    "I don't currently know of any places for lunch, why don't you tell me some?"
  end
end

command('add lunch',
  :required=>:location,
  :description => 'add a lunch location to the options'
) do |message, location|
  locations = data
  save_data(locations << location.strip) unless locations.include?(location.strip)
end

command('delete lunch',
  :required=>:location,
  :alias=>'del lunch',
  :description => 'delete a lunch location from the options'
) do |message, location|
  locations = data
  save_data(locations) if locations.delete(location.strip) 
end
