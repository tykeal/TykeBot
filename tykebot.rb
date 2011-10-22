#!/usr/bin/env ruby

$LOAD_PATH.push('lib/')

require 'rubygems'
require 'jabber/tykebot'
require 'utils'
require 'yaml'

env = ARGV[0] || 'test'

# Create a public Jabber::Bot
config = YAML::load( File.open( 'config/%s.yaml' % env ) ).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
bot = Jabber::TykeBot.new(config)

# Bring your new bot to life
bot.connect
# Connect the bot to the MUC
bot.join

# pull in plugins
$bot = bot
Dir.glob('plugins/*.rb').each{|f| require(f)}
Dir.glob('plugins/*/init.rb').each{|f| require(f)}

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
