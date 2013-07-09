require 'benchmark'
require 'stringio'
require 'lpxc'
require 'date'

module Instrument
  def self.bench_msg(message, level = 0, start_time, end_time, duration, build_id)
    out.puts "measure.#{message}.start=#{start_time} measure.#{message}.end=#{end_time} measure.#{message}.duration=#{duration} measure.#{message}.level=#{level} measure.#{message}.build_id=#{build_id}"
    out.send :flush
  end

  def self.instrument(cat, title = "", *args)
    ret        = nil
    start_time = DateTime.now.iso8601(6)
    duration = Benchmark.realtime do
      yield_with_block_depth do
        ret = yield
      end
    end
    end_time   = DateTime.now.iso8601(6)
    bench_msg(cat, block_depth, start_time, end_time, duration, build_id)

    ret
  end

  def self.out
    Thread.current[:out] ||= ENV['LOGPLEX_DEFAULT_TOKEN'] ? Lpxc.new : StringIO.new
  end

  def self.trace(name, *args, &blk)
    ret         = nil
    block_depth = 0

    instrument(name) { blk.call }
  end

  def self.yield_with_block_depth
    self.block_depth += 1
    yield
  ensure
    self.block_depth -= 1
  end

  def self.block_depth
    Thread.current[:block_depth] || 0
  end

  def self.block_depth=(value)
    Thread.current[:block_depth] = value
  end

  def self.build_id
    ENV['REQUEST_ID'] || ENV['SLUG_ID']
  end
end
