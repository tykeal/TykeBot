require 'forwardable'
class Plugin
  extend Forwardable
  attr_reader :bot, :name, :enabled, :file, :commands

  def_delegators :@bot, :publish, :on, :before, :send
  
  def initialize(bot,file)
    @bot=bot
    @file=file
    @dir=File.dirname(file)
    @name=parse_name(file)
    @enabled=true
    @commands = []
    @configs = []
  end

  # DSL helper function to require files from the plugins dir
  def plugin_require(filename)
    Kernel.require(File.join(@dir,filename))
  end
 
  # DSL helper function to calc an int in range of min,max with default value if nil
  # params:
  # n, a number or string or null
  # options:
  # :min=>i      (defaults to 1)
  # :max=>i      (defaults to 5)
  # :default=>i  (defaults to :min)
  def bound(n,options={})
    min=(options[:min]||1).to_i
    max=(options[:max]||5).to_i
    default=(options[:default]||min).to_i
    [[(n||default).to_i,min].max,max].min
  end

  # DSL to declare a command for this plugin
  # params:
  # [optional] name             # defaults to plugin name
  # [optional] options:
  # :description=>string        # 
  # :is_public, :html, :enable  # bool flags
  def command(*args,&block)
    return @working_command if @working_command
    name, options = _parse_name_and_options(args,self.name)
    @working_command = cmd = Command.new({:plugin=>self,:name=>name}.merge(options))
    yield(cmd) if block
    bot.add_command(cmd)
    @working_command=nil 
    cmd
  end

  # set working command description
  def description(s)
    command.description = s
  end

  # add alias to working command 
  def aliases(s)
    command.aliases(s)
  end

  # add action to workgin command
  def action(*args,&block)
    name, options = _parse_name_and_options(args)
    command.action({:name=>name}.merge(options),&block)
  end

  # resource() do ...
  # resource(name) do ...
  # resource(name,options) do ...
  # resource(options) do ...
  # resource(options) do ...
  def resource(*args,&block)
    command(*args) do |cmd|
      # add resource actions
      # TODO: Figure out override/mod/new default action...
      cmd.action(:name=>:sample,:default=>true) { (load_data||[]).sample }
      cmd.action(:name=>:list) { (load_data||[]).map{|l| l.to_s}.join("\n")}
      cmd.action(:name=>[:add,'+'],:required=>:d) {|msg,d| save_data( (load_data||[]) | [d] )}
      cmd.action(:name=>[:delete,:del,:-],:required=>:d) {|msg,d| debug("RESOURCE: - #{load_data.inspect} d: #{d.inspect}"); save_data( (load_data||[]) - [d] )}

      # now run as normal
      block.call(cmd) if block
    end
  end

  # warns if you override a plugin instance method
  def helper(name,&block)
    warn("Helper attempted to override existing method: #{name} in plugin #{self.name}") if self.methods.include?(name.to_s)
    (class << self; self; end).instance_eval{define_method(name,&block)}
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

  class Config
    def initialize(hash)
      @config = hash
      @wrappers = {}
    end
    def [](key)
      raise("Undefined configuration name #{key}.  Please declare your configuration options using the config() helper.") unless @wrappers[key]
      @wrappers[key].call
    end
    def _wrappers
      @wrappers
    end
    def _wrap(key, options={}, &block)
      raise("Illegal configuration name #{key}.  Please choose another name.") if methods.include?(key.to_s)
      method = lambda do
        value = @config[key]||options[:default]
        if block
          args = block.arity > 0 ? [value, @config[key], options[:default]][0..(block.arity)] : []
          block.call(*args)
        else
          value
        end
      end
      (class << self; self; end).instance_eval{ define_method(key,&method) }
      @wrappers[key] = method
    end
  end

  def config(*args, &block)
    # memoize
    @config_memo ||= Config.new(symbolize_keys(load_config))
    name,options = _parse_name_and_options(args)
    if name
      @config_memo._wrap(name,options,&block)
      self
    else
      @config_memo  
    end
  end

  def config_options()
    config._wrappers      
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

  def _parse_name_and_options(args,name=nil)
    options = {}
    args.each do |arg|
      case arg
      when Hash
        options = arg
      when String, Symbol
        name = arg
      end
    end
    [name,options]
  end

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

end
