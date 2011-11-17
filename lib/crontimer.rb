class CronTimer
  # timer queue
  attr_reader :timer

  def initialize(&handler)
    @timers = []
    @handler = handler if handler
    start_timer_thread
  end

  def add_timer(options, &callback)
    options[:timestamp] ||= Time.now + 1
    options[:requestor] ||= 'unknown'
    @timers << [options[:timestamp], options[:requestor], callback]
  end

  def delete_timer(options)
    options[:timestamp] ||= Time.now
    options[:requestor] ||= 'none'
    if options[:requestor] == 'none'
      # No specific requestor made the delete request
      # we're going to just be mean and kill the entire timer
      # set attached to this time slot
      @timers.delete_if { |ts,rq| ts == options[:timestamp] }
    else
      # Hunt down and erradicate all the events assigned to this
      # time slot by this requestor
      @timers.delete_if { |ts,rq| ts == options[:timestamp] && rq == options[:requestor] }
    end
  end

private
  def start_timer_thread
    timer_thread = Thread.new do
      loop do
        curtime = (Time.now)
        @timers -= @timers.sort.take_while{|t,r,c| t <= curtime}.each do |t,r,c|
          begin
            @handler ? @handler.call(t) : c.call
          rescue Exception
            error
          end
        end
        # wait a tick before we do anymore work
        sleep 0.1
      end
    end
  end

end

# vim:ts=2:sw=2:expandtab
