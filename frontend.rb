require "rubygems"
require "sinatra"
require "haml"

require "enumerator" # za collect Array-a s ID-om
require "timeout"
require "socket"

SOCK_TIMEOUT = 0.5
HELO_TIMEOUT = 0.5
RESP_TIMEOUT = 1.5

class Array
  def has(v)
    self.find{|x| return true if x==v}
  end
  false
end

class Back
  def initialize(s)
    raise "Adresa servera mora biti u formatu IP_ADDR:PORT" if ! s =~ /^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}:\d{1,5}$/
    @srv, @sock = s, nil
  end

  def get(str)
    case str
    when "helo"
      return "ok"
      break
    when "razredi"
      D.select "razredi"
      break
    end
  end

end

class BackendConnector
  def initialize(s)
    raise "Adresa servera mora biti u formatu IP_ADDR:PORT" if ! s =~ /^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}:\d{1,5}$/
    @srv  = s
    @sock = nil
  end

  def get(str)
    raise "str mora biti jedna linija sa komandama od slova, brojeva i razmaka" if ! str =~ /^[a-z0-9 ]+$/
    open_conn()
    @sock.print("#{str}\n")
    resp = Timeout::timeout(RESP_TIMEOUT){ @sock.gets.chop }
    @sock.gets
    close_conn()
    return resp
  end

  def open_conn()
    Timeout::timeout(SOCK_TIMEOUT){
      # napravi konekciju na server
      @sock = TCPSocket.open(@srv[/^(.+):/, 1], @srv[/:(.+)$/, 1])
    }
    @sock.print("HELO\n")
    if Timeout::timeout(HELO_TIMEOUT){ @sock.gets.chop } != "OK"
      raise "Server nije odgovorio na HELO"
    end
  end

  def close_conn()
    @sock.close
  end

end

B = BackendConnector.new("127.0.0.1:7007")

get '/' do
  # lista razreda
  # B.get "razredi"
end

# /a ili /2009_a
[%r{^/([a-z])\/?$}, %r{^/([\d]{2}?\d\d_[a-z])\/?$}].each do |path|
  # prva 2 tjedna za raz ..
  # tbl0 = B.get "razred 2009_a 0"
  # tbl1 = B.get "razred 2009_a 1"
  # po potrebi, AJAX: tblN = B.get "razred 2009_a N"
end
