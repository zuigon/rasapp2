require "rubygems"
require "socket"

PORT = 7007

ss = TCPServer.open(PORT)
puts "Starting server ..."
while true
  Thread.new(ss.accept) do |c|
    puts "Accepting connection from: #{c.peeraddr[2]}"
    begin
      while c
        # primanje podataka
        d = c.gets; d = d.chomp if d != nil

        if d == "HELO"
          c.puts "OK"
        elsif d == "TEST"
          c.puts Marshal.dump([1,2,3]).inspect # radi !
        elsif d == "END"
          c.close
          break
        else
          c.puts "You said: #{d}"
          c.flush
        end
      end
    rescue Exception => e
      puts "E: #{ e } (#{ e.class })"
    ensure
      c.close
      puts "ensure: Closing"
    end
  end
end
