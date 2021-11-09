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
  end

  #The interface to publish logs into the stream.
  #This function will set the log message to the current time in UTC.
  #If the buffer for this token's log messages is full, it will flush the buffer.
  def puts(msg, tok=@default_token)
  end

  #Wait until all of the data has been cleared from memory.
  #This is useful if you don't want your program to exit before
  #we are able to deliver log messages to logplex.
  def wait
  end

  private

  #Take a lock to read all of the buffered messages.
  #Once we have read the messages, we make 1 http request for the batch.
  #We pass the request off into the request queue so that the request
  #can be sent to LOGPLEX_URL.
  def flush
  end


  #This method must be called in order for the messages to be sent to Logplex.
  #This method also spawns a thread that allows the messages to be batched.
  #Messages are flushed from memory every 500ms or when we have 300 messages,
  #whichever comes first.
  def delay_flush
  end

  def interval_ready?
  end

  #Format the user message into RFC5425 format.
  #This method also prepends the length to the message.
  def fmt(data)
  end

  #We use a keep-alive connection to send data to LOGPLEX_URL.
  #Each request will contain one or more log messages.
  def outlet
  end
end
