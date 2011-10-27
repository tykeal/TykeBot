# TODO: figure out a standard way to deal with commands/params/resources...
# 
# maybe something REST like or RPC like... or something.
# list
#   get :resource-type
# show
#   get :resource-type/:id
# add
#   put :resource-type/:id :value
# remove
#   delete :resource-type/:id
# update
#   post :resource-type/:id :value
# rpc
#   post :resource-type/[:id]/:action :params
#

# namespace these functions with a silly space
module Plugins::PluginPlugin
  extend self

  def init(plugin)
    plugin_hash=plugin.bot.plugins.inject({}){|h,p| h[p.name]=p; h}
    (plugin.data_load_yaml||{}).each do |plugin_name,state|
      plugin_hash[plugin_name].enable(state) if plugin_hash[plugin_name]
    end
  end

  def save(plugin)
    plugin.data_save_yaml(
      plugin.bot.plugins.select{|p| !p.enabled}.inject({}){|h,p| h[p.name]=false; h})
  end
 
  def render_plugin(plugin)
    "%s%s\n    commands=[%s] src=%s" % [
      plugin.name,
      plugin.enabled==true ? '' : ' [DISABLED]',
      plugin.commands.map{|c| c[:name]}.join(", "),
      plugin.file,
    ]
  end

  def render_full_info(plugins)
    "Plugin Info:\n\n" +
      plugins.sort{|a,b| a.name<=>b.name}.map{|p| render_plugin(p) }.join("\n")
  end
  
  def command(plugin, sender, plugin_name, enable)
    # Returns the default help message describing the bot's command repertoire.
    # Commands are sorted alphabetically by name, and are displayed according
    # to the bot's and the commands's _public_ attribute.
    plugin_name = plugin_name.to_s.strip
    plugins = plugin.bot.plugins
    if plugin_name.length == 0
      render_full_info(plugins)
    else
      if p = plugins.detect{|p| p.name==plugin_name}
        case enable.to_s.strip.downcase
        when "enable"
          p.enable
          save(plugin)
          "plugin #{p.name} enabled."
        when "disable"
          p.disable
          save(plugin)
          "plugin #{p.name} disabled."
        when ''
          render_plugin(p)
        else
          "I don't know how to '#{enable}'.  Please say 'plugin #{p.name} enable' or 'plugin #{p.name} disable'"
        end
      else
         "unknown plugin '#{plugin_name}'.  Type plugin to see the list." 
      end
    end
  end 
end

plugin.add_command(
  :syntax       => 'plugin [<name> [enable|disable]]',
  :description  => 'manage plugins',
  :regex        => /^plugin(\s+.+?)?(\s+.+?)?$/,
  :is_public    => false
) do |*params|
  # a bit of a hack here...
  Plugins::PluginPlugin.command(*([plugin]+params)) 
end

plugin.add_init{Plugins::PluginPlugin.init(plugin)}

