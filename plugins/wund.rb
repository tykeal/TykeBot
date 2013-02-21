config :apikey, :description=>"weatherunderground.com api key"

command do
  description "query weather underground for forcast"
  action :html=>true, :required=>:zip, :optional=>:limit do |zip,limit|
    json = queryapi(zip)
    days = json["forecast"]["txt_forecast"]["forecastday"][0..(limit.to_i-1)]
    days.map{|day|"<b>%s</b><br/>%s" % [day["title"],day["fcttext"]].map{|s| h(s)}}.join("<br/>")
  end
end

helper :queryapi do |zip|
  http_get("http://api.wunderground.com/api/#{config.apikey}/forecast/q/#{zip}.json", :format=>:json)
end
