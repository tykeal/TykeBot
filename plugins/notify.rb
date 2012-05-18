require 'net/https'
require 'nokogiri'

config = {}
engines = ['nma', 'prowl']

command do
    description 'Send a notice to someone if they have notifications configured'

    action :required=>:handle,
        :optional=>:message,
        :description => 'Send a notice to handle if they have notifications configured' do |msg,handle,message|
        if (!config[handle].nil?)
            send_notice(msg.sender.nick,handle,message)
        else
            "#{handle} does not have a configuration set to send notices to"
        end
    end

    action :register,
        :required=>[:engine,:key],
        :optional=>:priority,
        :description => 'Register account for notifications' do |msg,engine,key,priority|
        handle = msg.sender.nick
        if (engines.include?(engine.downcase))
            config[handle] = {
                'engine'    => engine.downcase,
                'key'       => key,
                'priority'  => priority.nil? ? 0 : priority,
                'enabled'   => true,
                }
            save_data(config)
        else
            ret = "The engine '#{engine}' is not currently handled select from one of"
            engines.each do |e|
                ret = "#{ret} '#{e}'"
            end
            ret
        end
    end
end

helper :send_notice do |sender,handle,message|
    if (!config[handle]['key'].nil? && !config[handle]['engine'].nil? &&
        (config[handle]['enabled'].nil? || config[handle]['enabled'] == true))
        case config[handle]['engine'].downcase
        when 'nma' then
            send_nma(sender,handle,message)
        when 'prowl' then
            send_prowl(sender,handle,message)
        else
            "#{handle} is has an unknown notification engine"
        end
    else
        "#{handle} does not have an active configuration or is missing required options"
    end
end

helper :send_nma do |sender,handle,message|
    url = URI('https://www.notifymyandroid.com/publicapi/notify')

    post_form = {
        'apikey'        => config[handle]['key'],
        'application'   => bot.name,
        'event'         => "#{bot.name} Notification from #{sender}",
        'description'   => !message.nil? ? message : "You have been notified by #{sender}",
        'priority'      => !config[handle]['priority'].nil? ? config[handle]['priority'] : 0,
    }

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    https.ssl_timeout = 2

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

helper :send_prowl do |sender,handle,message|
end

init do
    config = load_data||{}
end
