#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require 'lib/tykebot'

env = ARGV[0] || 'test'
config_dir = ARGV[1] || 'config'

# Create a public Jabber::Bot
config = symbolize_keys(YAML::load(File.open( '%s/%s.yaml' % [config_dir,env] )))
bot = TykeBot.new(config.merge(:config_dir=>config_dir))

# load plugins by auto discovery
bot.discover_load_and_init_plugins

# run the bot
bot.run

# vim:ts=2:sw=2:expandtab:ai
