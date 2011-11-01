class CronTimer
  # timer queue
  attr_reader :timer

  def initialize()
    @timer = []
    start_timer_thread
  end

  def add_timer(options, &callback)
    options[:timestamp] ||= Time.now + 1
    options[:requestor] ||= 'unknown'
    @timer << [options[:timestamp], options[:requestor], callback]
  end

  def delete_timer(options)
    options[:timestamp] ||= Time.now
    options[:requestor] ||= 'none'
    if options[:requestor] == 'none'
      # No specific requestor made the delete request
      # we're going to just be mean and kill the entire timer
      # set attached to this time slot
      @timer.delete_if { |ts,rq| ts == options[:timestamp] }
    else
      # Hunt down and erradicate all the events assigned to this
      # time slot by this requestor
      @timer.delete_if { |ts,rq| ts == options[:timestamp] && rq == options[:requestor] }
    end
  end

private
  def start_timer_thread
    timer_thread = Thread.new do
      loop do
        if !@timer.empty?
          curtime = (Time.now)
          while !@timer.empty? && @timer.sort[0][0] <= curtime do
            timestamp, requestor, callback = @timer.sort[0]
            callback.call()
            delete_timer(:timestamp=>timestamp,:requestor=>requestor)
          end
        end

        # wait a tick before we do anymore work
        sleep 0.1
      end
    end
  end


end

# vim:ts=2:sw=2:expandtab
