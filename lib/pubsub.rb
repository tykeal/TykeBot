class PubSub
  attr_accessor :publish_thread
 
  def initialize(options={})
    @queue = Queue.new
    @subscribers={}
    start_publisher if options[:start_publisher]
  end

  # publish an event
  def publish(name, *params)
    @queue << [name,params]
  end

  # sign up to receive events
  def subscribe(name,&callback)
    (@subscribers[name]||=[]) << callback
  end

  # publish thread
  def start_publisher
    @publisher_thread=Thread.new do
      loop do
        name, params = @queue.pop # blocks
        (@subscribers[name]||[]).each {|callback| dispatch(params,callback)}
      end
    end
  end

  # join the publisher thread
  def join(limit=nil)
    @publisher_thread.join(limit)
  end

  # number of events waiting to publish
  def size
    @queue.size
  end

private
 
  def dispatch(params,callback)
    begin
      callback.call(*params)
    rescue
      error
    end
  end

end
