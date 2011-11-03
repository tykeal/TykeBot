def save
  data_save_yaml(
    bot.plugins.select{|p| !p.enabled}.inject({}){|h,p| h[p.name]=false; h})
end

def render_plugin(p)
  "%s%s\n    commands=[%s] src=%s" % [
    p.name,
    p.enabled==true ? '' : ' [DISABLED]',
    p.commands.sort.map{|c| "#{c.name}:#{c.public? ? 'public' : 'private'}"}.join(", "),
    p.file,
  ]
end

command(:plugin,
  :optional=>[:name,:action],
  :description  => 'manage plugins, action can be "enable" or "disable"',
  :is_public    => false
) do |message, name, action|
  
  # Returns the default help message describing the bot's command repertoire.
  # Commands are sorted alphabetically by name, and are displayed according
  # to the bot's and the commands's _public_ attribute.
  plugin_name = name.to_s.strip
  plugins = bot.plugins
  if plugin_name.length == 0
    "Plugin Info:\n\n" +
      plugins.sort{|a,b| a.name<=>b.name}.map{|p| render_plugin(p) }.join("\n")
  else
    if p = plugins.detect{|p| p.name==plugin_name}
      case action.to_s.strip.downcase
      when "enable", "disable"
        p.enable(action.to_s.strip.downcase=="enable")
        save
        "plugin #{p.name} #{action}d."
      when ''
        render_plugin(p)
      else
        "I don't know how to '#{action}'.  Please say 'plugin #{p.name} enable' or 'plugin #{p.name} disable'"
      end
    else
       "unknown plugin '#{plugin_name}'.  Type plugin to see the list." 
    end
  end

end

init do
  plugin_hash=bot.plugins.inject({}){|h,p| h[p.name]=p; h}
  (data_load_yaml||{}).each do |plugin_name,state|
    plugin_hash[plugin_name].enable(state) if plugin_hash[plugin_name]
  end
end
