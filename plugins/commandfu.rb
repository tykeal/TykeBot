command do
  description "show a random command line from commandlinefu.com"
  action :html=>true do
    json = (http_get "http://www.commandlinefu.com/commands/random/json", :format=>:json).first
    "# %s\n<br>%s\n<br><br><a href=\"%s\">\n%s</a>" % [json['summary'],json['command'],json['url'],json['url']]
  end
end
