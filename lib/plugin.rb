class Plugin
  attr_accessor :bot, :name 

  def initialize(bot,file)
    @bot=bot
    @dir=File.dirname(file)
    @name=parse_name(file)
    debug("Loading plugin: %s from: %s",@name,file)
  end

  def require(filename)
#    debug("REQUIRE: " + File.join(@dir,filename))
   Kernel.require(File.join(@dir,filename))
  end

  def config
    # memoize
    @config_memo ||= symbolize_keys(load_config)
  end

  def add_command(options,&block)
    bot.add_command(options,&block)
  end

  def debug(s,*args)
   Jabber::debuglog(args.empty? ? s : s % args)
  end

  def warn(s,*args)
   Jabber::warnlog(args.empty? ? s : s % args)
  end

private

  def load_config
    # look in bot config
    return bot.config[@name.to_sym] if bot.config[@name.to_sym]
 
    # try yaml files in config/ and plugin dir
    ['config',@dir].each do |d|
      f=File.join(d,"#{@name}.yaml")
      return YAML::load(File.open(f)) if File.exist?(f)
    end
    
    # no config found, use empty
    {}
  end

  def parse_name(file)
    n=File.basename(file.strip).gsub(/\.rb$/,'') 
    return n unless n=='init'
    return File.basename(File.dirname(file.strip)) 
  end

end
