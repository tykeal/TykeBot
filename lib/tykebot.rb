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

# vim:ts=2:sw=2:expandtab

require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/framework/bot'
require 'xmpp4r/muc'
require 'lib/commands'
require 'lib/tykemuc'

  class TykeBot
    # mixin command functions
    include Commands

    # Direct access to the Jabber::Framework::Bot
    attr_reader :jabber
    # Direct access to the Jabber::MUC::SimpleMUCClient
    attr_reader :room
    # Direct access to our listener_thread
    attr_reader :listener_thread
    # Access to our config object
    attr_reader :config
    # Commands
    attr_reader :commands

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

      @commands = { :spec => [], :meta => {} }

      # Default to asking about unknown commands.
      @config[:misunderstood_message] = @config[:misunderstood_message].nil? ? true : @config[:misunderstood_message]

    end

    # Connect the bot, making it available to accept commands.
    # You can specify a custom startup message with the ':startup_message'
    # configuration setting.
    def connect
      jid = Jabber::JID.new(@config[:jabber_id])
      @jabber = Jabber::Framework::Bot.new(jid, @config[:password])
      @room = TykeMuc.new(@jabber.stream)

      presence(@config[:presence], @config[:status], @config[:priority])

      jabber.stream.add_message_callback do |message|
        receive_message(message) if valid_chat?(message)
      end

      #deliver(@config[:master], (@config[:startup_message] || "#{@config[:name]} reporing for duty."))

      start_listener_thread
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

      @room.join(jid)

      @room.add_message_callback do |message|
        if valid_chat?(message)
          message.body = strip_prefix(message.body)
          receive_message(message) 
        end
      end
    end

    # Deliver a message to the specified recipient(s). Accepts a single
    # recipient or an Array of recipients.
    def deliver(to, message,html=false)
      return unless message
      Array(to).flatten.each { |t| 
        html ?  @jabber.send_message_xhtml(t, message) : @jabber.send_message(t, message) 
      }
    end

    # Send a message to the room.
    # this still has some problems in regards to xhtml
    def send(message,html=false)
      return unless message
      if message.is_a? Jabber::Message
        @room.say(message.body)
      else
        html ?  @room.say_xhtml(message) : @room.say(message)
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
        send(response) unless response.nil?
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
        send(response) unless response.nil?
      end
    end

    # Disconnect the bot. Once the bot has been disconnected, there is no way
    # to restart it by issuing a command.
    def disconnect
      if @jabber.stream.is_connected?
        deliver(@config[:master], "#{@config[:name]} disconnecting...")
        @jabber.stream.close
      end
    end

    # Returns an Array of masters
    def master
      @config[:master]
    end

    # Returns +true+ if the given Jabber id is a master, +false+ otherwise.
    def master?(jabber_id)
      @config[:master].include? jabber_id.to_s.sub(/\/.+$/, '')
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

    private

    def valid_chat?(message) #:nodoc:
      (message.body && 
      !message.first_element('delay')) && 
        (message.type == :chat &&
          message.from != @config[:name]) ||
        (message.type == :groupchat &&
          message.from.resource &&
          message.from.resource != @config[:name] &&
          strip_prefix(message.body))
    end

    # strip off the :chat_prefix by returning the first group match
    def strip_prefix(body)
      return unless p=body.to_s.strip.match(@config[:chat_prefix])
      p[1]
    end

    # generate response to the message with either a command response, a help msg
    # or nothing...
    def respond(sender,body)
      if cmd=match_command(sender,body)
        debug("COMMAND: #{cmd.inspect}")
        [cmd[:callback].call(sender, *(body.match(cmd[:regex]).captures)),cmd[:html]]
      else
        if @config[:misunderstood_message] && @config[:give_help]
          ["I don't understand '#{body}' Try saying 'help' " +
               "to see what commands I understand.", false]
        end
      end 
    end

    # check for a matching command out of the eligble set determined by sender
    def match_command(sender,body)
      (master?(sender) ? @commands[:spec] : @commands[:spec].select{|c| c[:is_public]}).
        detect {|command| body.match(command[:regex])}
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
              body = message.body 
              next unless @config[:is_public] || master?(sender)
              begin 
                case message.type
                when :chat
                  sender = message.from.to_s.sub(/\/.+$/, '')
                  deliver(sender,*respond(sender,body)) 
                when :groupchat
                  sender = message.from.resource
                  send(*respond(sender,body)) 
                end
              rescue
                warn("ERROR: " + $!)
                warn($!.backtrace.join("\n"))
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
   
    def debug(s)
      Jabber::debuglog(s)
    end
    
    def warn(s)
      Jabber::warnlog(s)
    end
  end
