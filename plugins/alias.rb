aliases = []
config :max_alias_depth, :default=>256

command do
  description "alias one command to another"

  action do 
    "There are %d aliases defined:\n%s" % [aliases.size,aliases.map{|a| "#{a.first}=#{a.last}"}.join("\n")]
  end
  
  action :name=>[:add,:+], :required=>:alias, :default=>true, :description=>'create a new alias foo=bar' do |a|
    find,replace = a.split('=',2)
    if replace && replace.size>0
      logger.debug("adding alias #{find}=#{replace}")
      add_alias(find,replace)
      aliases.sort!
    else
      remove_alias(find) 
    end
    save_data(aliases)
  end

  action :name=>[:delete,:del,'-'],:required=>:alias do |a| 
    find,replace = a.split('=',2)
    logger.debug("removing alias #{find}")
    remove_alias(find)
    save_data(aliases)
  end
end

# expand aliases before commands are processed
before(:command) do |message|
  # don't process aliases if command starts with !
  if message.body.to_s =~ /^!/
    message.body = message.body.to_s[1..-1]
  else
    # run aliases till no replacements found
    done=false
    times=0
    while(!done&&times<config[:max_alias_depth])
      done=true
      aliases.each do |a|
        re=/^#{Regexp::quote(a.first)}/
        if message.body.to_s =~ re
          message.body = message.body.to_s.gsub(re, a.last)
          done=false
        end
      end
      times+=1
    end
  end
end

init do
  (load_data||[]).each do |a|
    add_alias(*a)
  end
  aliases.sort!
end

helper :add_alias do |find,replace|
  remove_alias(find)
  aliases << [find,replace]
end

helper :remove_alias do |find|
  aliases.delete_if{|a| a.first==find}
end
