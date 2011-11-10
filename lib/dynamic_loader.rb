# loads a file in the scope of an object.
# this can be useful :)
#
# The object is obtained by what is passed into the constructor:
# either a Class object on which .new is called, or a block that 
# returns the instance to load.  The block is passed 2 params: |file,name|
#
# after a file is loaded, there is an instance method dynamic_info() which
# returns the file it was loaded from, along with the basename:
# {:name=>name,:file=>file}
class DynamicLoader

  def initialize(klass=nil,&block)
    @create= klass ? lambda{|*args| klass.new } : block
  end

  def create(file,name)
    @create.call(file,name)
  end

  def load(file)
    name = File.basename(file,".rb")
    returning(create(file,name)) do |instance|
      debug("loading: #{instance.class.name} #{name} from file #{file}...")
      instance.instance_eval{ eval(File.read(file), binding, file, 1) }
      debug("loaded: #{instance.class.name} #{name} from file #{file}")
      # getting the eigenclass ref in the right scope, so we can use outside locals
      (class <<instance; self; end).instance_eval do
        define_method(:dynamic_info) { {:name=>name,:file=>file} } # closure over local vars
      end
    end
  end

  def load_all(files)
    files.map{|file| load(file)}
  end

  def load_dir(dir_name)
    load_all Dir["#{dir_name}/*.rb"]
  end

end
