require 'time'

config :dates, :default=>{}, :discription=>'hash of date string keys and display values'

# turn config string dates into Time objects so we can compare/sort
holidays = config.dates.inject({}){|h,e| h[Time.parse(e.first)] = e.last; h}
helper :render do |dates|
  now = Time.now
  dates.map{|date| "%s: %s" % [time_diff_in_natural_language(now,date), holidays[date]]}.join("\n")
end

command do
  description 'Respond with upcoming holidays.'

  action :optional=>:n, :description=> 'Show the next <n=1> holidays.' do |message, n|
    now = Time.now
    count = bound(n,:default=>1,:max=>20)
    dates = holidays.keys.sort.select{|d| now < d}[0..(count-1)]
    render(dates)
  end

  action :list, :description=>'show all configured holidays' do |message|
    render(holidays.keys.sort)
  end
end
