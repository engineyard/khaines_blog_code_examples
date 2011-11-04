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
		

	def initialize
		@running = false

		@timers = TimerMap.new
		@block_buffer = []
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
	end

	def handle_timers
		now = Time.now
		while !@timers.empty? && @timers.next_time < now
			@timers.call_next_timer
		end
	end

	def empty?
		@timers.empty? && @block_buffer.empty?
	end

end
