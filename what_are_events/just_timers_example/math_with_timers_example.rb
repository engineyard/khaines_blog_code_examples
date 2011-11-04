require 'simplereactor'

puts <<ETXT
This demo will add a sequence of numbers to a sum, via a timer, once a second,
for four seconds, with the fifth number immediately following the fourth.
1+2+3+4+5 == 15. Let's see if that's the answer that we get.
ETXT

n = 0
reactor = SimpleReactor.new

reactor.add_timer(1) do
  puts "one"
  n += 1
end

reactor.add_timer(2) do
  puts "two"

  reactor.add_timer(1, n + 2) do |sum|
    puts "three"

    reactor.add_timer(1, sum + 3) do |sum|
      puts "four"
      n = sum + 4

      reactor.next_tick do
        puts "five"
        n += 5
        puts "n is #{n}\nThe reactor should stop after this."
      end
    end
  end
end

reactor.tick until reactor.empty?
