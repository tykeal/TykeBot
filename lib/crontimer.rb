class CronTimer
  # timer queue
  attr_reader :timer

  def initialize()
    @timer = { }
    start_timer_thread
  end

  def add_timer(options, &callback)
    options[:timestamp] ||= Time.now + 1
    options[:requestor] ||= 'unknown'
    if @timer[options[:timestamp].to_i].nil?
      @timer[options[:timestamp].to_i] = []
    end
    @timer[options[:timestamp].to_i] << [options[:requestor], callback]
  end

  def delete_timer(options)
    options[:timestamp] ||= Time.now
    options[:requestor] ||= 'none'
    if options[:requestor] == 'none'
      # No specific requestor made the delete request
      # we're going to just be mean and kill the entire timer
      # set attached to this time slot
      @timer.delete(options[:timestamp].to_i)
    else
      # Hunt down and erradicate all the objects assigned to this
      # time slot by this requestor
      events = @timer[options[:timestamp].to_i]
      if !events.nil?
        events.delete_if { |requestor, callback| requestor == options[:requestor] }
        if !events.empty?
          @timer[options[:timestamp].to_i] = events
        else
          @timer.delete(options[:timestamp].to_i)
        end
      end
    end
  end

private
  def start_timer_thread
    timer_thread = Thread.new do
      loop do
        if !@timer.empty?
          curtime = (Time.now)
          if @timer.has_key?(curtime.to_i)
            @timer[curtime.to_i].each do |requestor, callback|
              callback.call()
            end
            delete_timer(:timestamp=>curtime)
          end
        end

        # wait a tick before we do anymore work
        sleep 0.1
      end
    end
  end


end

# vim:ts=2:sw=2:expandtab
