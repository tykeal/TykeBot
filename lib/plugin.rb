require 'forwardable'
class Plugin
  extend Forwardable
  attr_reader :bot, :name, :enabled, :file, :commands

  def_delegators :@bot, :publish, :on, :send

  def initialize(bot,file)
    @bot=bot
    @file=file
    @dir=File.dirname(file)
    @name=parse_name(file)
    @enabled=true
    @commands = []
  end

  def plugin_require(filename)
    Kernel.require(File.join(@dir,filename))
  end

  #
  # :description=>string        #
  # :alias=>[]                  # of strings
  # :is_public, :html, :enable  # bool flags
  #
  def command(name,options={},&block)
    cmd={}
    cmd[:name] = name.to_s
    ([cmd[:name]] + Array(options[:alias])).each do |name|
      (cmd[:regex]||=[]) << command_regex(name,options[:required],options[:optional])
      (cmd[:syntax]||=[]) << command_syntax(name,options[:required],options[:optional])
    end
    cmd[:description] = options[:description]
    cmd[:is_public] = options.has_key?(:is_public) ? options[:is_public] : true
    cmd[:html] = options[:html]
    cmd[:enabled] = options.has_key?(:enabled) ? options[:enabled] : true
    add_command(cmd,&block)
  end

  # advanced
  def add_command(options,&block)
    command = Command.new({:plugin=>self}.merge(options),&block)
    @commands << command
    bot.add_command(command)
  end

  def data_file(filename=nil)
    # todo isolate plugins in their own dir
    filename ||= default_data_filename
    File.join(bot.config[:data_dir] || 'data',filename)
  end

  # defaults to yaml and plugin name .yaml
  def save_data(data,filename=nil)
    filename=data_file(filename)
    case File.extname(filename).downcase
    when ".yaml",".yml"
      open(filename,"w"){|f| f.puts YAML.dump(data)}
    when ".json"
      open(filename,"w"){|f| f.puts JSON.generate(data)}
    else
      open(filename,"w"){|f| f.puts data }
    end
  end

  # defaults to yaml and plugin name .yaml
  def load_data(filename=nil)
    filename=data_file(filename)
    return unless File.exist?(filename)
    case File.extname(filename).downcase
    when ".yaml",".yml"
      YAML.load(File.open(filename))
    when ".json"
      JSON.parse(File.read(filename))
    else
      File.read(filename)
    end
  end

  def config
    # memoize
    @config_memo ||= symbolize_keys(load_config)
  end

  def init(&block)
    bot.add_plugin_init(self,&block)
  end

  def disable
    enable(false)
  end

  def enable(enabled=true)
    @commands.each{|c| c.enabled=enabled}
    @enabled=enabled
  end

  # @deprecated
  # for backward plugin compatibility
  def plugin
    self
  end

  # timeout - min num of seconds before calling callback
  # options
  #   :requestor (defaults to self.name)
  def timer(timeout,options={},&callback)
    bot.timer.add_timer(:timestamp=>Time.now+timeout.to_i, :requestor=>options[:requestor]||name,&callback)
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

  def default_data_filename(ext=".yaml")
    name + ext
  end

  def parse_name(file)
    n=File.basename(file.strip).gsub(/\.rb$/,'') 
    return n unless n=='init'
    return File.basename(File.dirname(file.strip)) 
  end

  def command_regex(name,required,optional)
    Regexp.compile("^%s%s%s$" % [
      Regexp.quote(name.to_s),
      Array(required).map{"(\s+.+?)"}.join,
      Array(optional).map{"(\s+.+?)?"}.join
    ])
  end

  def command_syntax(name,required,optional)
    s="#{name}" 
    s+=' ' + Array(required).map{|n|"<#{n}>"}.join(" ") if required
    s+=' ' + Array(optional).map{|n|"[<#{n}>]"}.join(" ") if optional
    s
  end
end
