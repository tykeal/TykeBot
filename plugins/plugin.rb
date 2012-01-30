command :is_public=>false do
  description "Manage plugins."

  action :description=>'show summary for each plugin' do
    "Plugin Info:\n\n" +
      bot.plugins.sort{|a,b| a.name<=>b.name}.map{|p| render_plugin(p) }.join("\n")
  end

  action :required=>:name, :description=>'show detail for the specificed plugin' do |msg,name|
    plugin_do(name){|p| render_plugin(p)}
  end

  action :enable, :required=>:name, :discription=>'enable all commands for this plugin.' do |msg,name|
    plugin_do(name) do |p| 
      p.enable(true)
      save
      "plugin #{name} enabled."
    end
  end

  action :disable, :required=>:name, :discription=>'disable all commands for this plugin.' do |msg,name|
    plugin_do(name) do |p| 
      p.enable(false)
      save
      "plugin #{name} disabled."
    end
  end
end

helper :save do
  save_data(
    bot.plugins.select{|p| !p.enabled}.inject({}){|h,p| h[p.name]=false; h})
end

helper :render_plugin do |p|
  "%s%s\n    commands=[%s] src=%s" % [
    p.name,
    p.enabled==true ? '' : ' [DISABLED]',
    p.commands.sort.map{|c| "#{c.name}:#{c.public? ? 'public' : 'private'}"}.join(", "),
    p.file,
  ]
end

helper :plugin_do do |name,&block|
  if p = bot.plugins.detect{|p| p.name==name}
    block.call(p)
  else
    "Unknown plugin '#{name}'.  Type plugin to see the installed plugins."
  end
end

init do
  # restore plugins enabled/disabled state
  plugin_hash=bot.plugins.inject({}){|h,p| h[p.name]=p; h}
  (load_data||{}).each do |plugin_name,state|
    plugin_hash[plugin_name].enable(state) if plugin_hash[plugin_name]
  end
end

