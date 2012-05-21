require 'net/https'
require 'nokogiri'

config = {}
engines = ['nma', 'prowl']
options = ['key', 'priority', 'enabled', 'password']
nma_url = 'https://www.notifymyandroid.com/publicapi/notify'
prowl_url = 'https://api.prowlapp.com/publicapi/add'

started = false

command do
    description 'Send a notice to someone if they have notifications configured'

    action :required => :handle,
        :optional    => :message,
        :description => 'Send a notice to handle if they have notifications configured' do |msg,handle,message|
        if (!config[handle].nil?)
            send_notice(msg.sender.nick,handle,message,nil)
        else
            "#{handle} does not have a configuration set to send notices to"
        end
    end

    action :register,
        :required    => [:nick,:engine,:key],
        :optional    => [:priority,:password],
        :description => 'Register account for notifications (private message command only)' do |msg,nick,engine,key,priority,password|
        if msg.chat?
            engine.downcase!
            if (!engines.include?(engine))
                ret = "The engine '#{engine}' is not currently handled select from one of"
                engines.each do |e|
                    ret += " '#{e}'"
                end
                return ret
            end

            # deal with registration differently if the nick is already being managed
            if (!config[nick].nil?)
                # if they have a password that overrides the jid == jid check
                if (config[nick]['password'] != '*' && password.nil?)
                    "I'm sorry, this nick is password protected. Please supply a password."
                elsif (config[nick]['password'] != '*' && password == config[nick]['password'])
                    do_registration(nick,engine,key,priority,true,msg.sender.jid,password)
                elsif (config[nick]['jid'] == msg.sender.jid)
                    do_registration(nick,engine,key,priority,true,msg.sender.jid,password)
                else
                    "I'm sorry, you are trying to update this nick from an account that didn't register it. Please update from the account that registered the nick. If in the future you would like to make changes to the nick from a different account please register a password."
                end
            else
                if (!bot.room.roster[nick].nil? && (get_stripped_jid(nick) == msg.sender.jid))
                    do_registration(nick,engine,key,priority,true,msg.sender.jid,password)
                else
                    'You must be currently using the nick you wish to register.'
                end
            end
        else
            'Do your configuration in private chat please. Now go revoke this key and get a new one.'
        end
    end

    action :unregister,
        :required    => :nick,
        :optional    => :password,
        :description => 'Unregister nick from notificaitons (private message command only)' do |msg,nick,password|
        if msg.chat?
            if (!config[nick].nil?)
                if (config[nick]['password'] != '*' && password.nil?)
                    "I'm sorry, this nick is password protected. Please supply a password."
                elsif (config[nick]['password'] != '*' && password == config[nick]['password'])
                    config.delete(nick)
                    save_data(config)
                elsif (config[nick]['jid'] == msg.sender.jid)
                    config.delete(nick)
                    save_data(config)
                else
                    "This nick requires that you manage it from the registering account"
                end
            else
                "#{nick} does not currently have a configuration to display"
            end
        else
            'You can only do this from private chat.'
        end
    end

    action :status,
        :required    => :nick,
        :description => 'Inform if nick has notifications configured and enabled' do |nick|
        if (!config[nick].nil?)
            if (config[nick]['enabled'])
                "#{nick} has notifications enabled"
            else
                "#{nick} does not have notifications enabled"
            end
        else
            "#{nick} does not have notifications configured"
        end
    end

    action :display,
        :required    => :nick,
        :optional    => :password,
        :description => 'Display current configuration for nick (private message command only)' do |msg,nick,password|
        if (msg.chat?)
            if (!config[nick].nil?)
                if (config[nick]['password'] != '*' && password.nil?)
                    "I'm sorry, this nick is password protected. Please supply a password."
                elsif (config[nick]['password'] != '*' && password == config[nick]['password'])
                    display_configuration(nick)
                elsif (config[nick]['jid'] == msg.sender.jid)
                    display_configuration(nick)
                else
                    "I'm sorry, you are trying to get configuration information on this nick from an account that didn't register it. Please get request the information from the account that registered the nick. If, in the future you would like to make changes to the nick from a different account please register a password."
                end
            else
                "#{nick} does not currently have a configuration to display"
            end
        else
            if (password.nil?)
                'This command only works in private messaging'
            else
                "This command only works in private messaging. Since you provided a password it's recommended you now change it"
            end
        end
    end

    action :configure,
        :required    => [:nick,:option,:setting],
        :optional    => :password,
        :description => 'Set configurations options (private message command only)' do |msg,nick,option,setting,password|
        if (msg.chat?)
            if (!config[nick].nil?)
                option.downcase!
                if (options.include?(option))
                    if (config[nick]['password'] != '*' && password.nil?)
                        "I'm sorry, this nick is password protected. Please supply a password."
                    elsif (config[nick]['password'] != '*' && password == config[nick]['password'])
                        do_config_update(nick,option,setting)
                    elsif (config[nick]['jid'] == msg.sender.jid)
                        do_config_update(nick,option,setting)
                    else
                        "I'm sorry, you are trying to set configuration information on this nick from an account that didn't register it. Please set the information from the account that registered the nick. If, in the future you would like to make changes to the nick from a different account please register a password."
                    end
                else
                    ret = "The option '#{option}' is not currently handled select from one of"
                    options.each do |o|
                        ret += " '#{o}'"
                    end
                    ret
                end
            else
                "#{nick} does not currently have a configuration. Please use register instead"
            end
        else
            if (password.nil?)
                'This command only works in private messaging'
            else
                "This command only works in private messaging. Since you provided a password it's recommended you now change it"
            end
        end
    end
end

helper :get_stripped_jid do |nick|
    bot.room.roster[nick].each do |node|
        if (node.attributes['xmlns'] == 'http://jabber.org/protocol/muc#user')
            return node.children[0].attributes['jid'].split('/')[0]
        end
    end
end

helper :display_configuration do |nick|
    ret  = "\n"
    ret += "nick: #{nick}\n"
    ret += "key: #{config[nick]['key']}\n"
    ret += "priority: #{config[nick]['priority']}\n"
    ret += "enabled: #{config[nick]['enabled']}\n"
    ret += "registering account: #{config[nick]['jid']}"
    ret
end

helper :do_config_update do |nick,option,setting|
    case option
    when 'password' then
        if (setting == '')
            setting = '*'
        end
    when 'enabled' then
        setting.downcase!
        if (setting == 'true')
            setting = true
        elsif (setting == 'false')
            setting = false
        else
            return "enabled required true or false not '#{setting}'"
        end
    end
    config[nick][option] = setting
    save_data(config)
end

helper :do_registration do |nick,engine,key,priority,enabled,jid,password|
    config[nick] = {
        'engine'    => engine,
        'key'       => key,
        'priority'  => priority || 0,
        'enabled'   => enabled,
        'jid'       => jid,
        'password'  => password || '*',
    }
    save_data(config)
end

helper :send_notice do |sender,handle,message,event|
    if (!config[handle]['key'].nil? && !config[handle]['engine'].nil? &&
        (config[handle]['enabled'].nil? || config[handle]['enabled'] == true))
        case config[handle]['engine'].downcase
        when 'nma' then
            send_nma(sender,handle,message,event)
        when 'prowl' then
            send_prowl(sender,handle,message,event)
        else
            "#{handle} is has an unknown notification engine"
        end
    else
        "#{handle} does not have an active configuration or is missing required options"
    end
end

helper :send_nma do |sender,handle,message,event|
    url = URI(nma_url)

    post_form = {
        'apikey'        => config[handle]['key'],
        'application'   => bot.name,
        'event'         => event || "#{bot.name} Notification from #{sender}",
        'description'   => !message.nil? ? message : "You have been notified by #{sender}",
        'priority'      => !config[handle]['priority'].nil? ? config[handle]['priority'] : 0,
    }

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    https.ssl_timeout = 2
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https.ca_file = bot.config[:ca_file]

    https.start do |http|
        req = Net::HTTP::Post.new(url.path)
        req.set_form_data(post_form)
        response = https.request(req)

        case response
        when Net::HTTPSuccess then
            #"#{handle} successfully notified"
            #response.body + " success!"
            doc = Nokogiri::XML(response.body)
            if (doc.xpath('/nma/success').length > 0)
                "#{handle} successfully notified"
            else
                doc.xpath('/nma/error')[0].text
            end
        else
            response.error!
        end
    end
end

helper :send_prowl do |sender,handle,message,event|
    url = URI(prowl_url)

    post_form = {
        'apikey'        => config[handle]['key'],
        'application'   => bot.name,
        'event'         => event || "#{bot.name} Notification from #{sender}",
        'description'   => !message.nil? ? message : "You have been notified by #{sender}",
        'priority'      => !config[handle]['priority'].nil? ? config[handle]['priority'] : 0,
    }

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    https.ssl_timeout = 2
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https.ca_file = bot.config[:ca_file]

    https.start do |http|
        req = Net::HTTP::Post.new(url.path)
        req.set_form_data(post_form)
        response = https.request(req)

        case response
        when Net::HTTPSuccess then
            doc = Nokogiri::XML(response.body)
            if (doc.xpath('/prowl/success').length > 0)
                "#{handle} successfully notified"
            else
                doc.xpath('/prowl/error')[0].text
            end
        else
            response.error!
        end
    end
end

# Avoid the bot from generating pages on replay during startup
on :join do |bot|
    timer(5) { started = true }
end

on :firehose do |bot,message|
    if message.body? && started
        config.keys.each do |nick|
            if bot.room.roster[nick].nil?
                if !message.body.match(nick).nil?
                    send_notice(message.sender.nick,nick,"#{bot.config[:room]}@conference.#{bot.config[:server]}: <#{message.sender.nick}> #{message.body}",'Highlight')
                end
            end
        end unless message.sender.bot?
    end
end

init do
    config = load_data||{}
end
