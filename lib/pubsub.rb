class PubSub

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
  def on(name,&callback)
    (@subscribers[name]||=[]) << callback
  end

  # publish thread
  def start_publisher
    @publisher_thread=Thread.new do
      loop do
        begin 
          name, params = @queue.pop # blocks
          (@subscribers[name]||[]).each {|callback| dispatch(params,callback)}
        rescue Exception => e
          error(e)
        end
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
 
  # call the onr's callback with published params
  # and trap errors aggressively.  For now we just log.
  def dispatch(params,callback)
    begin
      callback.call(*params)
    rescue Exception => e
      error(e)
    end
  end

end
