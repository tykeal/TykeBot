# create namespace
module Plugins ; end

# todo: maybe move into namespace?
class Plugin
  attr_reader :bot, :name, :enabled, :file, :commands

  def initialize(bot,file)
    @bot=bot
    @file=file
    @dir=File.dirname(file)
    @name=parse_name(file)
    @enabled=true
    @commands = []
  end

  def require(filename)
    Kernel.require(File.join(@dir,filename))
  end

  def data_file(filename)
    # todo isolate plugins in their own dir
    filename ||= "#{name}.yaml"
    File.join(bot.config[:data_dir] || 'data',filename)
  end

  def data_save_yaml(data,filename=nil)
    open(data_file(filename),"w"){|f| f.puts YAML::dump(data)}
  end

  def data_load_yaml(filename=nil)
    YAML.load(File.open(data_file(filename))) if File.exist?(data_file(filename))
  end

  def config
    # memoize
    @config_memo ||= symbolize_keys(load_config)
  end

  def add_command(options,&block)
    @commands << bot.add_command({:plugin=>self}.merge(options),&block)
  end

  def add_init(&block)
    bot.add_plugin_init(self,&block)
  end

  def disable
    enable(false)
  end

  def enable(enabled=true)
    @commands.each{|c| c[:enabled]=enabled}
    @enabled=enabled
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
    [bot.config[:config_dir],@dir].each do |d|
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
