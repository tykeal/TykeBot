def symbolize_keys(hash)
  hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
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

