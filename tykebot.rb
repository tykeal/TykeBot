#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require 'lib/tykebot'
require 'lib/utils'
require 'lib/plugin'

env = ARGV[0] || 'test'
config_dir = ARGV[1] || 'config'

# Create a public Jabber::Bot
config = symbolize_keys(YAML::load(File.open( '%s/%s.yaml' % [config_dir,env] )))
bot = TykeBot.new(config.merge(:config_dir=>config_dir))

# Bring your new bot to life
bot.connect
# Connect the bot to the MUC
bot.join

# load plugins by auto discovery
bot.load_plugins(bot.discover_plugins)

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
