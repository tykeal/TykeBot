require 'time'
$bot.add_command(
	:syntax  => 'holiday <n>',
	:description => 'get the next n holidays, n defaults to 1.  n can also be all. ex: holiday, holiday all, holiday 3',
	:regex       => /^holiday(\s+.+)?$/,
  :is_public   => true
) do |sender, n|
  holidays = plugin_load_yaml_config(__FILE__).inject({}){|h,e| h[Time.parse(e.first)] = e.last; h}

  now = Time.now
  count = (n||'1').strip
  message = holidays.size if count == 'all'
  dates = holidays.keys.sort.select{|d| now < d}[0..(count.to_i-1)]
  dates.map{|date| "%s: %s" % [time_diff_in_natural_language(now,date), holidays[date]]}.join("\n")
end

