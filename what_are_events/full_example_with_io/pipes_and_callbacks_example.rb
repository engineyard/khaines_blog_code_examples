require 'simplereactor'

chunk = "01234567890" * 30

reactor = SimpleReactor.new

reader, writer = IO.pipe

reactor.attach writer, :write do |write_io|
  bytes_written = write_io.write chunk
  puts "Sent #{bytes_written} bytes: #{chunk[0..(bytes_written - 1)]}"

  chunk.slice!(0,bytes_written)
  if chunk.empty?
    reactor.detach write_io
    write_io.close
  end
end

reactor.attach reader, :read do |read_io|
  if read_io.eof?
    puts "finished; detaching and closing."
    reactor.detach read_io
    read_io.close
  else
    puts "received: #{read_io.read 200}"
  end
end

reactor.add_timer(2) do
  puts "Timer called; the code should exit after this."
end

reactor.tick until reactor.empty?
