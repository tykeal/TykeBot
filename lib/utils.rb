require 'forwardable'
require 'logger'
require 'net/http'
require 'net/https'
require 'cgi'
require "lib/naive_bayes"

def h(s)
  begin
    s ? CGI::escapeHTML(s) : ""
  rescue
    error
    "" # screw it!
  end
end

# todo replace with a decent logging system.
class StupidLogger
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG
    @logger.progname = "BOT"
    @logger.formatter = lambda{|severity,time,progname,msg| "%s [%s] %5s: %s\n" % [time.strftime("%Y-%m-%d %H:%M:%S"), progname, severity, msg.to_s]}
  end

  def level=(l)
    @logger.level=l
  end
 
  def info(*args)
    @logger.info format(args)
  end

  def debug(*args)
    @logger.debug format(args)
  end

  def warn(*args)
    @logger.warn format(args)
  end

  # last arg must be the exception to log backtrace
  # valid calls:
  # error
  # error("string")
  # error("string %s",'arg')
  # error($!)
  # error("string",$!)
  # error("string %s",'arg1',...,$!)
  def error(*args)
    # check last arg if backtrace, then check $!, else just go as normal
    e=args.last||$!
    if e.respond_to? :backtrace
      @logger.error "%s%s\n%s" % [format(args[0..-2]), " " + e, e.backtrace.join("\n")]
    else
      @logger.error format(args)
    end
  end

private
  def format(args)
    case args.size
    when 0 then ''
    when 1 then args.first
    else args.first % args[1..-1]
    end
  end
end

BOTLOGGER = StupidLogger.new
def logger; BOTLOGGER; end
def debug(*args); logger.debug(*args); end
def info(*args); logger.info(*args); end
def warn(*args); logger.warn(*args); end
def error(*args); logger.error(*args); end

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

def http_get(uri_str, options={})
  limit = options[:limit] || 10
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0

  url = URI.parse(uri_str)
  http = Net::HTTP.new(url.host, url.port)
  request = Net::HTTP::Get.new(url.path + (url.query ?  "?" + url.query : ''), {"User-Agent" => "curl"})
  response = http.start {|http| http.request(request) }

  case response
  when Net::HTTPSuccess     then response
    case options[:format]
    when :json
      JSON.parse(response.body)
    else
      response
    end
  when Net::HTTPRedirection then http_get(response['location'],options.merge(:limit=>limit - 1))
  else
    response.error!
  end
end

good = File.open("plugins/twss_data/good.txt","r")
bad = File.open("plugins/twss_data/bad.txt","r")
TWSS_CLASSIFIER = NaiveBayes.new(["she_said","she_didnt_say"])
good.each{|line| TWSS_CLASSIFIER .train("she_said",line)}
bad.each{|line| TWSS_CLASSIFIER .train("she_didnt_say",line)}
good.close
bad.close
