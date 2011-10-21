$bot.add_command(
  :syntax      => 'lunch [list]',
  :description => 'get a lunch suggestion or list all locations currently known',
  :regex       => /^lunch(\s+list\s*)?$/,
  :is_public   => true
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

$bot.add_command(
  :syntax      => 'add lunch <location>',
  :description => 'add a lunch location to the options',
  :regex       => /^add lunch\s+(.+)?$/,
  :is_public   => true
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

$bot.add_command(
  :syntax      => 'delete lunch [location]',
  :description => 'delete a lunch location from the options',
  :regex       => /^delete lunch\s+(.+)?$/,
  :alias       => [ :syntax => 'del lunch [location]', :regex => /^del lunch\s+(.+)?$/ ],
  :is_public   => true
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
