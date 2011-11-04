class SimpleReactor

  # Simple; not particularly efficient for many entries.
  class TimerMap < Hash
    def []=(k,v)
      super
      @sorted_keys = keys.sort
      v
    end

    def delete k
      r = super
      @sorted_keys = keys.sort
      r
    end

    def next_time
      @sorted_keys.first
    end

    def shift
      if @sorted_keys.empty?
        nil
      else
        first_key = @sorted_keys.shift
        val = self.delete first_key
        [first_key, val]
      end
    end

    def add_timer time, *args, &block
      time = case time
      when Time
        Time.to_i
      else
        Time.now + time.to_i
      end
      
      self[time] = [block, args] if block
    end

    def call_next_timer
      _, v = self.shift
      block, args = v
      block.call(*args)
    end
  end
    
  Events = [:read, :write, :error].freeze
  attr_reader :ios

  def self.run &block
    reactor = self.new

    reactor.run &block
  end

  def initialize
    @running = false
    @ios = Hash.new do |h,k|
      h[k] = {
        :events => [],
        :callbacks => {},
        :args => [] }
    end

    @timers = TimerMap.new
    @block_buffer = []
  end

  def attach io, *args, &block
    events = Events & args
    args -= events

    @ios[io][:events] |= events

    setup_callback io, events, *args, &block

    self
  end

  def setup_callback io, events, *args, &block
    i = @ios[io]
    events.each {|event|  i[:callbacks][event] = block }
    i[:args] = args
    i
  end

  def detach io
    @ios.delete io
  end

  def add_timer time, *args, &block
    time = time.to_i if Time === time
    @timers.add_timer time, *args, &block
  end

  def next_tick &block
    @block_buffer << block
  end

  def tick
    handle_pending_blocks
    handle_events
    handle_timers
  end

  def run
    @running = true

    yield self if block_given?

    tick while @running
  end

  def stop
    @running = false
  end

  def handle_pending_blocks
    @block_buffer.length.times { @block_buffer.shift.call }
  end

  def handle_events
    unless @ios.empty?
      pending_events.each do |io, events|
        events.each do |event|
          if @ios.has_key? io
            if handler = @ios[io][:callbacks][event]
              handler.call io, *@ios[io][:args]
            end
          end
        end
      end
    end
  end

  def handle_timers
    now = Time.now
    while !@timers.empty? && @timers.next_time < now
      @timers.call_next_timer
    end
  end

  def empty?
    @ios.empty? && @timers.empty? && @block_buffer.empty?
  end

  def pending_events
    # Trim our IO set to only include those which are not closed.
    @ios.reject! {|io, v| io.closed? }

    h = find_handles_with_events @ios.keys

    if h
      handles = Events.zip(h).inject({}) {|handles, ev| handles[ev.first] = ev.last; handles}

      events = Hash.new {|h,k| h[k] = []}

      Events.each do |event|
        handles[event].each { |io| events[io] << event }
      end

      events
    else
      {} # No handles
    end
  end

  def find_handles_with_events keys
    select find_ios(:read), find_ios(:write), keys, 0.01
  end

  def find_ios event
    @ios.select { |io, h| h[:events].include? event}.collect { |io, data| io }
  end
end
