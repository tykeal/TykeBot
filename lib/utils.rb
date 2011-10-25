# location must be __FILE__ for now to determine plugin's dir
def plugin_require(location, filename)
  require File.join(File.dirname(location),filename)
end

# looks up the config file for this plugin
# first in the config dir, and second in the plugin's dir
# location must be __FILE__ for now to determine plugin's dir
def plugin_load_yaml_config(location)
  # look in config, then plugin config
  plugin_dir = File.dirname(location)
  filename = "#{File.basename(plugin_dir)}.yaml"

  file1 = File.join('config',filename)
  file2 = File.join(plugin_dir,filename)
  if File.exist?(file1)
    YAML::load(File.open(file1))
  elsif File.exist?(file2)
    YAML::load(File.open(file2))
  else
    raise "config not found! #{filename}"
  end
end

# doesn't handle leap years... suck it
def time_diff_in_natural_language(from_time, to_time)
  distance_in_seconds = ((to_time - from_time).abs).round
  components = []

  [[:year,60*60*24*365],[:week,60*60*24*7],[:day,60*60*24]].each do |name,interval|
    # For each interval type, if the amount of time remaining is greater than
    # one unit, calculate how many units fit into the remaining time.
    if distance_in_seconds >= interval
      delta = (distance_in_seconds / interval.to_f).floor
      distance_in_seconds -= delta*interval
      components << (delta == 1 ? "1 #{name}" : ('%s %ss' % [delta,name]))
    end
  end

  components.join(", ") + (from_time > to_time ? ' ago' : '')
end

