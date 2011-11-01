module PubSub

  def publish(name, *params)
    ((@subscribers||{})[name]||[]).each do |callback| 
      begin 
        callback.call(*params)
      rescue 
        warn("error in callback for %s: %s %s",name,$!,$!.backtrace.join("\n"))
      end
    end
  end

  def subscribe(name,&callback)
    ((@subscribers||={})[name]||=[]) << callback
  end

end
