require 'time'
command do
  description 'show anniversary info from date in '
  action :required=>:date, :optional=>:n do |date,n|
    n = (n || 1).to_i
    now = Time.now
    start = Time.parse(date).to_a
    years = (1..n).map{|i| start[5]+=1; "%d Year: %s" % [i,time_diff_in_natural_language(now, Time.local(start[0]+i, *start[1..-1]))]}
    "Anniversaries:\n#{years.join("\n")}"
  end
end

