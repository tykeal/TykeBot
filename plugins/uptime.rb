upsince=Time.now
command do
  description "Show current uptime for the bot"
  action do
    captures = (`uptime`.match /up (?:(?:(\d+) days,)?\s+(\d+):(\d+)|(\d+) min)/).captures
    elapsed_seconds = captures.zip([86440, 3600, 60, 60]).inject(0) do |total, (x,y)|
      total + (x.nil? ? 0 : x.to_i * y)
    end
    systemup = Time.now-elapsed_seconds
    "In my most recent life I have been alive for %s and my world has existed for %s." % [
      time_diff_in_natural_language(upsince,Time.now),
      time_diff_in_natural_language(systemup,Time.now)
    ]
  end
end
