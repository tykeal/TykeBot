module PubSub

  def publish(name, *params)
    ((@subscribers||{})[name]||[]).each do |callback| 
      begin 
        callback.call(*params)
      rescue 
        error("error in callback for %s:",name,$!)
      end
    end
  end

  def subscribe(name,&callback)
    ((@subscribers||={})[name]||=[]) << callback
  end

end
