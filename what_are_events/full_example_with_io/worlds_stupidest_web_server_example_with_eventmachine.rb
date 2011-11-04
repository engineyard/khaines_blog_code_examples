require 'rubygems'
require 'eventmachine'

module ServerHandler
  def initialize(buffer)
    @buffer = buffer
    super
  end

  def receive_data data
    send_data "HTTP/1.1 200 OK\r\nContent-Length:#{@buffer.length}\r\nContent-Type:text/plain\r\nConnection:close\r\n\r\n#{@buffer}"
    close_connection_after_writing
  end

end

module KeyHandler
  def initialize buffer
    @counter = 0
    @buffer = buffer
    super
  end

  def receive_data data
    @counter += 1
    if data.chomp.empty?
      EM.stop
    else
      @buffer << data
    end
  end
end


puts <<ETXT
Type some text and press  after each line. The reactor is attached to
STDIN and also port 9949, where it listens for any connection and responds with
a basic HTTP response containing whatever has been typed to that point. These
two dramatically different IO streams are being handled simultaneously. Type
a blank line to exit, or wait one minute, and a timer will fire which causes the
reactor to stop and the program to exit.
ETXT

buffer = ''

EventMachine.run do
  EM.start_server('0.0.0.0',9949,ServerHandler,buffer)

  EM.attach(STDIN, KeyHandler, buffer)

  EM.add_timer(60) do
    EM.stop
  end
end
