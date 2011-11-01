#--
# Copyright (c) 2011 Andrew Grmiberg <tykeal@bardicgrove.org>
# TykeBot created with the help & and blatant ripping off of the following
#
# jabber-bot:
# Copyright (c) 2011 Brett Stimmerman <brettstimmerman@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   * Neither the name of this project nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# mucbot:
# "THE BEER-WARE LICENSE" (Revision 42):
# <vivien@didelot.org> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return. Vivien Didelot
#++


require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/framework/bot'
require 'xmpp4r/muc'
require 'lib/command'
require 'lib/tykemuc'
require 'lib/crontimer'
require 'lib/pubsub'

class TykeBot
    include PubSub
    # Direct access to the Jabber::Framework::Bot
    attr_reader :jabber
    # Direct access to the Jabber::MUC::SimpleMUCClient
    attr_reader :room
    # Direct access to our listener_thread
    attr_reader :listener_thread
    # Access to our config object
    attr_reader :config
    # plugins
    attr_reader :plugins
    # CronTimer
    attr_reader :timer

    # Creates a new Jabber::Framework::Bot object with the specified +config+
    # Hash, which must contain +jabber_id+, +password+, and +master+ at a
    # minimum.
    #
    # You may optionally give your bot a custom +name+. If +name+ is omitted,
    # the username portion of +jabber_id+ is used instead.
    #
    # You may choose to restrict a TykeBot to listen only to its master(s),
    # or make it +public+.
    #
    # You may optionally specify a Jabber +presence+, +status+, and +priority+.
    # If omitted, they each default to +nil+.
    #
    # By default, a TykeBot has only a single command, 'help [<command>]',
    # which displays a help message for the specified command, or all commands
    # if <command> is omitted.
    #
    # If you choose to make a public bot, only the commands you specify as
    # public, as well as the default 'help' command, will be public.
    #
    #   # A minimally configured private bot with a single master.
    #   # Bot only good for direct one on one chat
    #   bot = TykeBot.new(
    #     :jabber_id => 'bot@example.com',
    #     :password  => 'secret',
    #     :master    => 'master@example.com'
    #   )
    #
    #   # A highly configured public bot with a custom name, mutliple masters,
    #   # Jabber presence, status, and priority.
    #   # Bot also capable of doing groupchat
    #   masters = ['master1@example.com', 'master2@example.com']
    #
    #   bot = Jabber::Bot.new(
    #     :name      => 'PublicBot',
    #     :jabber_id => 'bot@example.com',
    #     :server    => 'example.com',
    #     :password  => 'secret',
    #     :master    => masters,
    #     :is_public => true,
    #     :presence  => :chat,
    #     :priority  => 5,
    #     :status    => 'Hello, I am PublicBot.'
    #     :room      => 'testroom',
    #     :chat_prefix => /^!(.+)$/
    #   )
    #
    def initialize(config)
      @config = config

      @config[:is_public] ||= false
      @config[:chat_prefix] ||= /^!(.+)$/

      if @config[:name].nil? || @config[:name].length == 0
        @config[:name] = @config[:jabber_id].sub(/@.+$/, '')
      end

      Jabber.debug = @config[:debug] || false

      # Default to asking about unknown commands.
      @config[:misunderstood_message] = @config[:misunderstood_message].nil? ? true : @config[:misunderstood_message]

      @plugins=[]
      @commands = []
      @inits=[]
      @timer=CronTimer.new()
    end

    # all-in-one helper for default behaviour
    def discover_load_and_init_plugins
      load_plugins(discover_plugins)
      init_plugins
    end

    # Look in the file system in the dirs specified in the config or default to 'plugins/'
    # supports black listing of plugins by name in config using config[:blacklist_plugins]
    def discover_plugins
      plugins={}
      blacklist=(config[:blacklist_plugins]||[]).map(&:to_s)
      plugin_dirs=config[:plugin_dirs]||['plugins']
      debug("auto discovering plugins: dirs: #{plugin_dirs.inspect} blacklist: #{blacklist.inspect}")
      (config[:plugin_dirs]||['plugins']).map{|dir| Dir.glob(File.join(dir,'*.rb')) + Dir.glob(File.join(dir,'*','init.rb'))}.flatten.compact.uniq.map do |f|
        p=Plugin.new(self,f)
        unless blacklist.include?(p.name)
          plugins[p.name] ||= p
        end
      end
      plugins.values
    end

    # Load the array of plugins passed.  This can be populated by calling discover_plugins.
    def load_plugins(plugins)
      plugins.each do |plugin|
        begin
          debug("Loading plugin: %s from: %s",plugin.name,plugin.file)
          plugin.load
          @plugins << plugin
        rescue
          error("failed to load plugin:",$!)
          exit if config[:exit_on_load_error]
        end
      end
    end

    # a one time callback after plugins are loaded and bot is connected/ready
    def add_plugin_init(plugin,&block)
      debug("adding plugin %s to init list",plugin.name)
      @inits << [plugin,block]
    end

    # call after loading plugins
    def init_plugins
      @inits.each do |plugin,callback|
        begin
          debug("initializing plugin #{plugin.name}")
          callback.call(plugin)
        rescue
          error("failed initialing plugin: %s",plugin.name,$!)
        end
      end
    end

    # Connect the bot, making it available to accept commands.
    # You can specify a custom startup message with the ':startup_message'
    # configuration setting.
    def connect
      jid = Jabber::JID.new(@config[:jabber_id])
      begin
        @jabber = Jabber::Framework::Bot.new(jid, @config[:password])
        # Make sure we're connected before trying to attach a room
        if connected?
          @room = TykeMuc.new(@jabber.stream)

          presence(@config[:presence], @config[:status], @config[:priority])

          jabber.stream.add_message_callback do |message|
            receive_message(message) if valid_chat?(message)
          end

          start_listener_thread
        end
      rescue Exception => e
        # Do nothing
        # AKA eat the baby right now
      end
    end

    def connected?
      if jabber.nil?
        return false
      else
        jabber.stream.is_connected?
      end
    end

    # Join the bot to the room and enable callbacks.
    def join
      nick = @config[:name]
      serv = @config[:server]
      room = @config[:room]

      jid = Jabber::JID.new("#{room}@conference.#{serv}/#{nick}")

      # We need a connection or else we'll blow up
      if connected?
        @room.join(jid)

        @room.add_message_callback do |message|
          if valid_chat?(message)
            message.body = strip_prefix(message.body)
            receive_message(message) 
          end
        end
      end
    end

    # Customize a welcome message for new connected people.
    # The given callback takes a |user| parameter and
    # should return the welcome message.
    #
    #   welcome { |person| "Hello #{person}!" }
    def welcome(&callback)
      @room.add_join_callback do |message|
        response = callback.call(message.from.resource)
        send(:text=>response) unless response.nil?
      end
    end

    # Customize a leave message for people leaving room.
    # The given callback takes a |user| parameter and
    # should return the leave message.
    #
    #   leave { |person| "Apparently #{person} didn't like something I said :(" }
    def leave(&callback)
      @room.add_leave_callback do |message|
        response = callback.call(message.from.resource)
        send(:text=>response) unless response.nil?
      end
    end

    # Disconnect the bot. Once the bot has been disconnected, there is no way
    # to restart it by issuing a command.
    def disconnect
      if @jabber.stream.is_connected?
        send(:to=>@config[:master], :text=>"#{@config[:name]} disconnecting...")
        @jabber.stream.close
      end
    end

    # Returns an Array of masters
    def master
      Array(@config[:master])
    end

    # Returns +true+ if the message/jabber-id is from a master +false+ otherwise.
    def master?(message)
      sender = case message
      when Jabber::Message
        sender(message)
      when String
        message
      end
      master.include?(sender)
    end

    def groupchat?(message)
      message.type==:groupchat
    end

    # Returns the jabber-id of the sender
    # TODO: fix for :groupchat messages.
    def sender(message)
      if groupchat?(message)
        # this is broken.
        message.from.resource.to_s
      else
        message.from.to_s.sub(/\/.+$/, '')
      end
    end

    # Sets the bot presence, status message and priority.
    def presence(presence=nil, status=nil, priority=nil)
      @config[:presence] = presence
      @config[:status]   = status
      @config[:priority] = priority

      status_message = Jabber::Presence.new(presence, status, priority)
      @jabber.stream.send(status_message) if @jabber.stream.is_connected?
    end

    # Sets the bot presence. If you need to set more than just the presence,
    # use presence() instead.
    #
    # Available values for presence are:
    #
    #   * nil   : online
    #   * :chat : free for chat
    #   * :away : away from the computer
    #   * :dnd  : do not disturb
    #   * :xa   : extended away
    #
    def presence=(presence)
      presence(presence, @config[:status], @config[:priority])
    end

    # Set the bot priority. Priority is an integer from -127 to 127. If you need
    # to set more than just the priority, use presence() instead.
    def priority=(priority)
      presence(@config[:presence], @config[:status], priority)
    end

    # Set the status message. A status message is just a String, e.g. 'I am
    # here.' or 'Out to lunch.' If you need to set more than just the status
    # message, use presence() instead.
    def status=(status)
      presence(@config[:presence], status, @config[:priority])
    end

    # send text or xhtml to the room or jabber-id
    #
    # :text=>nil | string
    # :xhtml=>nil | xhtml-string
    # :to=>nil | jabber-id | [jabber-id]
    #
    # requires :text or :xhtml
    # if :to is nil, this will send to the room
    def send(options)
      text = options[:text]
      xhtml = options[:xhtml]
      to = options[:to]
      return unless text || xhtml
      if to
        Array(to).flatten.each { |t| 
          xhtml ?  @jabber.send_message_xhtml(t, xhtml, text) : @jabber.send_message(t, text) 
        }
      else
        xhtml ?  @room.say_xhtml(xhtml,text) : @room.say(text)
      end
    end

    # NOTE: this returns a new object, so can't add commands via this
    # have to use add_command.
    def commands(public_only=true)
      @commands.select(&:enabled).reject{|c| public_only && !c.public?}
    end

    def add_command(command)
      @commands << command
    end

    private

    def valid_chat?(message) #:nodoc:
      (message.body && 
      !message.first_element('delay')) && 
        ((message.type == :chat &&
          sender(message) != @config[:name]) ||
        (message.type == :groupchat &&
          sender(message) != @config[:name] &&
          strip_prefix(message.body)))
    end

    # strip off the :chat_prefix by returning the first group match
    def strip_prefix(body)
      return unless p=body.to_s.strip.match(@config[:chat_prefix])
      p[1]
    end

    # Creates a new Thread dedicated to listening for incoming chat messages.
    # When a chat message is received, the bot checks if the sender is its
    # master. If so, it is tested for the presence commands, and processed
    # accordingly. If the bot itself or the command issued is not made public,
    # a message sent by anyone other than the bot's master is silently ignored.
    #
    # Only the chat & groupchat message type are supported. Other message types
    # such as error are not supported.
    def start_listener_thread
      @listener_thread = Thread.new do
        loop do
          if received_messages?
            received_messages do |message|
              from_master = master?(message)
              next unless @config[:is_public] || from_master
              commands(!from_master).each do |cmd| 
                begin
                  cmd.message(self,message)
                rescue
                  error
                end
              end
            end
          end
          sleep 1
        end
      end
    end

    # Returns an array of messages received since the last time
    # received_messages was called. Passing a block will yield each message in
    # turn, allowing you to break part-way through processing (especially
    # useful when your message handling code is not thread-safe (e.g.,
    # ActiveRecord).
    #
    # e.g.:
    #
    #   jabber.received_messages do |message|
    #     puts "Received message from #{message.from}: #{message.body}"
    #   end
    def received_messages(&block)
      dequeue(:received_messages, &block)
    end

    # Returns true if there are unprocessed received messages waiting in the
    # queue, false otherwise.
    def received_messages?
      !queue(:received_messages).empty?
    end

    def receive_message(message)
      queue(:received_messages) << message
    end

    # Basic queue
    def queue(queue) #:nodoc:
      @queues ||= Hash.new { |h,k| h[k] = Queue.new }
      @queues[queue]
    end

    # dequeueing #:nodoc:
    def dequeue(queue, non_blocking = true, max_items = 100, &block)
      queue_items = []
      max_items.times do
        queue_item = queue(queue).pop(non_blocking) rescue nil
        break if queue_item.nil?
        queue_items << queue_item
        yield queue_item if block_given?
      end
      queue_items
    end
   
public
    def debug(s,*args)
      Jabber::debuglog(args.empty? ? s : s % args)
    end
 
    def warn(s,*args)
      Jabber::warnlog(args.empty? ? s : s % args)
    end

    def error(*args)
     e=args.pop||$!
     if e.respond_to? :backtrace
       s=(args.first ? (args.first % args[1..-1]) + ' ' : '')
       warn("ERROR: %s%s %s", s, e, e.backtrace.join("\n"))
     else
       warn("ERROR: %s",e,*args)
      end
    end

end

# vim:ts=2:sw=2:expandtab
