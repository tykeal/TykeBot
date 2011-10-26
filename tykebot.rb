#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require 'lib/tykebot'
require 'lib/utils'
require 'lib/plugin'

env = ARGV[0] || 'test'

# Create a public Jabber::Bot
config = symbolize_keys(YAML::load(File.open( 'config/%s.yaml' % env )))
bot = TykeBot.new(config)

# Bring your new bot to life
bot.connect
# Connect the bot to the MUC
bot.join

# pull in plugins
plugins = (config[:plugin_dirs]||['plugins']).map{|dir| Dir.glob(File.join(dir,'*.rb')) + Dir.glob(File.join(dir,'*','init.rb'))}.flatten.compact.uniq.map do |f| 
  def make_binding(plugin); binding ; end
  p=Plugin.new(bot,f)
  eval(open(f){|file|file.read}, make_binding(p))
  p
end

# Just wait till our listener exists out.
# Should probably do this in a different fashion but this work for now
while (true)
  # reconnect the bot if we've dropped for some reason
  if !bot.connected?
    sleep(20)
    bot.connect
    bot.join
  end
  # verify we're connected before we try to join the thread
  if !bot.connected?
    bot.listener_thread.join(0.15)
  end
end

# vim:ts=2:sw=2:expandtab:ai
