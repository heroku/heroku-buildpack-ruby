require 'time'
require 'net/http'
require 'uri'
require 'thread'
require 'timeout'

class Lpxc

  #After parsing opts and initializing defaults, the initializer
  #will start 2 threads. One thread for sending HTTP requests and another
  #thread for flushing log messages to the outlet thread periodically.
  #:hash => {}:: A data structure for grouping log messages by token.
  #:request_queue => SizedQueue.new::  Contains HTTP requests ready for outlet thread to deliver to logplex.
  #:default_token => nil:: You can specify a token that will be used for any call to Lpxc#puts that doesn't include a token.
  #:structured_data => '-':: Structured-data field for syslog headers. Ignored by logplex.
  #:msgid => '-'::  Msg ID field for syslog headers. Ignored by logplex.
  #:procid => 'lpxc':: Proc ID field for syslog headers. This will show up in the Heroku logs tail command as: app [lpxc].
  #:hostname => 'myhost':: Hostname field for syslog headers. Ignored by logplex.
  #:max_reqs_per_conn => 1_000:: Number of requests before we re-establish our keep-alive connection to logplex.
  #:conn_timeout => 2:: Number of seconds before timing out a sindle request to logplex.
  #:batch_size => 300:: Max number of log messages inside single HTTP request.
  #:flush_interval => 0.5:: Fractional number of seconds before flushing all log messages in buffer to logplex.
  #:logplex_url => \'https://east.logplex.io/logs':: HTTP server that will accept our log messages.
  #:disable_delay_flush => nil:: Force flush only batch_size is reached.
  def initialize(opts={})
    @hash_lock = Mutex.new
    @hash              = opts[:hash]              || Hash.new
    @request_queue     = opts[:request_queue]     || SizedQueue.new(1)
    @default_token     = opts[:default_token]     || ENV['LOGPLEX_DEFAULT_TOKEN']
    @structured_data   = opts[:structured_data]   || "-"
    @msgid             = opts[:msgid]             || "-"
    @procid            = opts[:procid]            || "lpxc"
    @hostname          = opts[:hostname]          || "myhost"
    @max_reqs_per_conn = opts[:max_reqs_per_conn] || 1_000
    @conn_timeout      = opts[:conn_timeout]      || 2
    @batch_size        = opts[:batch_size]        || 300
    @flush_interval    = opts[:flush_interval]    || 0.5
    @logplex_url       = URI(opts[:logplex_url]   || ENV["LOGPLEX_URL"] ||
      raise("Must set logplex url."))

    #Keep track of the number of requests that the outlet
    #is processing. This value is used by the wait function.
    @req_in_flight = 0

    #Initialize the last_flush to an arbitrary time.
    @last_flush = Time.now + @flush_interval

    #Start the processing threads.
    Thread.new {outlet}
    Thread.new {delay_flush} if opts[:disable_delay_flush].nil?
  end

  #The interface to publish logs into the stream.
  #This function will set the log message to the current time in UTC.
  #If the buffer for this token's log messages is full, it will flush the buffer.
  def puts(msg, tok=@default_token)
    @hash_lock.synchronize do
      #Messages are grouped by their token since 1 http request
      #to logplex must only contain log messages belonging to a single token.
      q = @hash[tok] ||= SizedQueue.new(@batch_size)
      #This call will block if the queue is full.
      #However this should never happen since the next command will flush
      #the queue if we add the last item.
      q.enq({:t => Time.now.utc, :token => tok, :msg => msg})
      flush if q.size == q.max
    end
  end

  #Wait until all of the data has been cleared from memory.
  #This is useful if you don't want your program to exit before
  #we are able to deliver log messages to logplex.
  def wait
    sleep(0.1) until
      @hash.length.zero? &&
      @request_queue.empty? &&
      @req_in_flight.zero?
  end

  private

  #Take a lock to read all of the buffered messages.
  #Once we have read the messages, we make 1 http request for the batch.
  #We pass the request off into the request queue so that the request
  #can be sent to LOGPLEX_URL.
  def flush
    @hash.each do |tok, msgs|
      #Copy the messages from the queue into the payload array.
      payloads = []
      msgs.size.times {payloads << msgs.deq}
      return if payloads.nil? || payloads.empty?

      #Use the payloads array to build a string that will be
      #used as the http body for the logplex request.
      body = ""
      payloads.flatten.each do |payload|
        body += "#{fmt(payload)}"
      end

      #Build a new HTTP request and place it into the queue
      #to be processed by the HTTP connection.
      req = Net::HTTP::Post.new(@logplex_url.path)
      req.basic_auth("token", tok)
      req.add_field('Content-Type', 'application/logplex-1')
      req.body = body
      @request_queue.enq(req)
      @hash.delete(tok)
      @last_flush = Time.now
    end
  end


  #This method must be called in order for the messages to be sent to Logplex.
  #This method also spawns a thread that allows the messages to be batched.
  #Messages are flushed from memory every 500ms or when we have 300 messages,
  #whichever comes first.
  def delay_flush
    loop do
      begin
        if interval_ready?
          @hash_lock.synchronize {flush}
        end
        sleep(0.01)
      rescue => e
      end
    end
  end

  def interval_ready?
    (Time.now.to_f - @last_flush.to_f).abs >= @flush_interval
  end

  #Format the user message into RFC5425 format.
  #This method also prepends the length to the message.
  def fmt(data)
    pkt = "<190>1 "
    pkt += "#{data[:t].strftime("%Y-%m-%dT%H:%M:%S+00:00")} "
    pkt += "#{@hostname} "
    pkt += "#{data[:token]} "
    pkt += "#{@procid} "
    pkt += "#{@msgid} "
    pkt += "#{@structured_data} "
    pkt += data[:msg]
    "#{pkt.size} #{pkt}"
  end

  #We use a keep-alive connection to send data to LOGPLEX_URL.
  #Each request will contain one or more log messages.
  def outlet
    loop do
      http = Net::HTTP.new(@logplex_url.host, @logplex_url.port)
      http.use_ssl = true if @logplex_url.scheme == 'https'
      begin
        http.start do |conn|
          num_reqs = 0
          while num_reqs < @max_reqs_per_conn
            #Blocks waiting for a request.
            req = @request_queue.deq
            @req_in_flight += 1
            resp = nil
            begin
              Timeout::timeout(@conn_timeout) {resp = conn.request(req)}
            rescue => e
              next
            ensure
              @req_in_flight -= 1
            end
            num_reqs += 1
          end
        end
      rescue => e
      ensure
        http.finish if http.started?
      end
    end
  end

end
