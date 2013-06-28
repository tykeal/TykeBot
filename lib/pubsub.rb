class PubSub

  def initialize
    @queue = Queue.new
    @subscribers={}
    @befores={}
  end

  # publish an event
  def publish(name, *params)
    @queue << [name,params]
  end

  # sign up to receive events
  def on(name,&callback)
    (@subscribers[name]||=[]) << callback
  end

  def before(name,&callback)
    (@befores[name]||=[]) << callback
  end

  def start_publisher_thread
    @publisher_thread||=Thread.new do
      loop do
        begin 
          name, params = @queue.pop # blocks
          (@befores[name]||[]).each {|callback| dispatch(params,callback)}
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
