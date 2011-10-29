command(:lunch,
  :optional=>:list,
  :description => 'get a lunch suggestion or list all locations currently known'
) do |sender, list|
  lunchdata = 'data/lunch.yaml'
  locations = []
  if File.exists?(lunchdata)
    locations = YAML::load(File.open(lunchdata))
  end

  if !locations[0].nil?
    if list.nil?
      message = "How about " + locations[rand(locations.length)] + "?"
    else
      message = "I know the following locations:\n" + locations.join("\n")
    end
  else
    message = "I don't currently know of any places for lunch, why don't you tell me some?"
  end
  message
end

command('add lunch',
  :required=>:location,
  :description => 'add a lunch location to the options'
) do |sender, location|
  lunchdata = 'data/lunch.yaml'
  locations = []

  if File.exists?(lunchdata)
    locations = YAML::load(File.open(lunchdata))
  end

  if !locations.include?(location.strip)
    locations << location.strip
  end

  File.open(lunchdata, 'w') do |file|
    file.puts YAML::dump(locations)
  end
end

command('delete lunch',
  :required=>:location,
  :alias=>'del lunch',
  :description => 'delete a lunch location from the options'
) do |sender, location|
  lunchdata = 'data/lunch.yaml'
  locations = []

  if File.exists?(lunchdata)
    locations = YAML::load(File.open(lunchdata))
  end

  if !locations[0].nil?
    locations.delete(location.strip)

    File.open(lunchdata, 'w') do |file|
      file.puts YAML::dump(locations)
    end
  else
    "I don't seem to have any locations to delete!  Maybe you should try adding some first."
  end
end
