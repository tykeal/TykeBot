require 'net/http'
require 'net/https'
require 'cgi'

def debug(s,*args)
  Jabber::debuglog(args.empty? ? s : s % args)
end

def warn(s,*args)
  Jabber::warnlog(args.empty? ? s : s % args)
end

# last arg must be the exception to log backtrace
# valid calls:
# error("string")
# error("string %s",'arg')
# error($!)
# error("string",$!)
# error("string %s",'arg1',...,$!)
def error(*args)
 e=args.pop||$!
 if e.respond_to? :backtrace
   s=(args.first ? (args.first % args[1..-1]) + ' ' : '')
   warn("ERROR: %s%s %s", s, e, e.backtrace.join("\n"))
 else
   warn("ERROR: %s",e,*args)
  end
end

def symbolize_keys(hash)
  hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
end

# doesn't handle leap years... suck it
def time_diff_in_natural_language(from_time, to_time)
  distance_in_seconds = ((to_time - from_time).abs).round
  components = []

  [[:year,60*60*24*365],[:week,60*60*24*7],[:day,60*60*24]].each do |name,interval|
    # For each interval type, if the amount of time remaining is greater than
    # one unit, calculate how many units fit into the remaining time.
    if distance_in_seconds >= interval
      delta = (distance_in_seconds / interval.to_f).floor
      distance_in_seconds -= delta*interval
      components << (delta == 1 ? "1 #{name}" : ('%s %ss' % [delta,name]))
    end
  end

  components.join(", ") + (from_time > to_time ? ' ago' : '')
end

def http_get(uri_str, limit = 10)
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0

  url = URI.parse(uri_str)
  http = Net::HTTP.new(url.host, url.port)
  request = Net::HTTP::Get.new(url.path + (url.query ?  "?" + url.query : ''))
  response = http.start {|http| http.request(request) }

  case response
  when Net::HTTPSuccess     then response
  when Net::HTTPRedirection then fetch(response['location'], limit - 1)
  else
    response.error!
  end
end

class Array
  def sample ; self[rand(size)] ; end
end

class File
  # reverse_readline
  def reverse_readline
    buffer = 1024
    lines = []
    done = false
    seek(0,SEEK_END)
    while !done
      if pos > buffer
         to_read = buffer
         seek(-to_read,SEEK_CUR)
      else
         to_read = pos
         seek(0,SEEK_SET)
         done=true
      end
      chunk = read(to_read)
      chunk += lines.first unless lines.empty?
      lines = chunk.split("\n")
      lines[(done ? 0 : 1)..-1].reverse.each do |line| 
        result = yield line
        break unless result 
      end
      seek(-to_read,SEEK_CUR)
    end
  end
end

