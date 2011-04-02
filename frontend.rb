%w[rubygems haml sinatra date ./sati-lib enumerator logger].each{|x| require x}
gem "ruby-mysql", "= 2.9.3"
require "mysql"

$log = Logger.new('app.log')

$log_file = File.new("sinatra.log", "a")
STDOUT.reopen($log_file)
STDERR.reopen($log_file)

POC_DATUM = ["6.9.2010", 0]
DANI = %w(pon uto sri cet pet sub ned)

class Array
  def has(v)
    self.find{|x| return true if x==v}
  end
  false
end

configure do
  error 404 do
    haml "%h1.err Grijeska cetiri nula cetiri ..."
  end
  error 500 do
    haml "%h1.err ... excuse me while I kiss the sky! (Greska)\n%h2.err greska se dogodila sada da se ne bi dogodila kasnije"
  end
  error do
    haml "%h1.err Grijeska cetiri nula cetiri ..."
  end
  use Rack::Session::Cookie, :key => '_rasapp2_key1', :domain => 'vps1.bkrsta.co.cc', :secret => 'setnoirsehdoairsh'

  set :raise_errors, Proc.new { false }
  set :show_exceptions, false

  LOGGER = Logger.new("sinatra.log")
end

helpers do
  def logger
    LOGGER
  end
end

def query_and_log(q)
  puts "SQL: #{q.inspect}"
  r = @c.query q
  puts "RET: #{r.count.inspect}"
  r
end

class SeqConn # MySQL client
  def initialize(host, user, passw, db)
    @data = [host, user, passw, db]
    @c = nil
  end
  def open
    $log.debug "mysql conn open"
    @c = Mysql.real_connect *@data
  end
  def close
    $log.debug "mysql conn close"
    @c.close
  end
  def razredi
    @c.query("select concat(gen, '_', raz) from razredi order by gen, raz asc;").to_a
  end
  def raspored(raz_id)
    raise "raz_id must be int!" if ! raz_id =~ /^\d+$/
    h={}; i=0
    @c.query("select sat, pon, uto, sri, cet, pet, sub from rasporedi where raz_id=#{raz_id} order by sat;").each_hash{|x| h[i]=x; i+=1}
    return h
  end
  def eventi(raz_id, tj)
    puts "eventi(): "
    puts raz_id
    puts tj
    raise "raz_id must be int!" if ! raz_id =~ /^\d+$/
    raise "tj must be int!" if ! tj =~ /^\d+$/
    query_and_log("select weekday(dan), txt, dsc from eventi where raz_id=#{raz_id} and week(dan)=(week(date(now())-1)+#{tj});").to_a
  end
  def raz_id(gen, raz)
    r = query_and_log("select id from razredi where gen='#{gen}' and raz='#{raz}' limit 1;").first[0]
  end
  def query(str)
    query_and_log str
  end
end

B = SeqConn.new  *(File.readlines("db.conf").first[/(.+)\n?/,1].split(":")[0..3])
$log.debug "B = SeqConn.new"

def smjena(datum) # in: <Time>; out: 0 ili 1 (jut. ili pod.)
  d=Date.strptime(POC_DATUM[0], "%d.%m.%Y")
  r=((datum.strftime("%W").to_i - d.strftime("%W").to_i).abs + POC_DATUM[1])%2
  r=(r+1)%2 if DateTime.now.strftime("%w")=="0"
  r
end

def prvi_dan_tj
  DateTime.now - DateTime.now.strftime("%w").to_i
end

def raz(str) # 2009_a => 2.a
  d = DateTime.parse("#{str.split('_')[0].to_i}/09", "%Y/%m")
  return false if d>DateTime.now
  "#{(1+((DateTime.now-d)/365).to_i)}.#{str[/_(.+)$/, 1]}"
end

def ras_za_tj(raz_str, tj)
  ra = B.raspored(B.raz_id(*raz_str.split('_')))
  rr={}; ra.each{|r| rr[x=r[1]["sat"].to_i]=r[1]; rr[x].delete("sat")}
  rr
end


get '/' do
  B.open
  @razredi = B.razredi.collect{|x| "#{x[0]}"}
  B.close
  haml :razredi
end

# /a ili /2009_a
[%r{^/([a-z])\/?$}, %r{^/([\d]{2}?\d\d_[a-z])\/?$}].each do |path|
  get path do |str|
    @str = str
    B.open
    @str = "20#{str}" if @str =~ /^\d\d_[a-z]$/

    @n_tj = 2 # broj tjedana za prikaz
    ept   = nil
    @tbls = []
    @ev   = []
    (0..@n_tj-1).each{|i|
      r = ras_za_tj(@str, i)
      @tbls << r
      @ev[i]={}
      ept=1 and break if r=={}
      DANI.each{|x| @ev[i][x]=[] }
      B.eventi(B.raz_id(*@str.split("_")), i).each{|e| @ev[i][DANI[e[0].to_i]] << [e[1], e[2]] }
    }

    haml ept ? :ras_nije_podesen : :razred
  end
end

def ras_html(tbl, tj, eventi)
  @tj = tj
  @ras = tbl
  @eventi = eventi
  haml :ras_tbl, :layout => false
end

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  "
body { font-family: serif; }
a:link, a:visited, a:active, a:hover { color: blue; }
#tbl_ras { text-align: center; border-collapse: collapse; cursor: default; }
.empty { color: lightgray; }
.gray { background-color: lightgray; }
.wgray { background-color: #eee; }
.blue { background-color: lightblue; }
.uline { text-decoration: underline; }
.events_l { line-height: 1.2em; }
.gcal_event { list-style: none; }
.hasdesc { /*color: blue;*/ }
.right { text-align: right; }
ul { margin: 0 auto; list-style-type: none; padding: 0; }
table#tbl_ras tr td .sati { margin-right: 20px; }
.help { color: gray; text-decoration: italic; margin-left: 5px; }
.danas { background-color: lightblue; }
.tek_sat { color: red; }
.ozn1 { background-color: #FFCC00; }
.ozn_dz { background-color: red; }
.highlight { background-color: #BFEFFF; }
ul.svi_razredi { width: 200px; position: relative; }
ul.svi_razredi li { padding: 10px 0; font-size: 200%; }
ul.svi_razredi li a { text-decoration: none; color: red; font-family: georgia; text-decoration: overline underline; letter-spacing: 5px; }
h1.err, h2.err { font-family: georgia; font-style: italic; }
h1.raz_naslov { font-family: georgia; font-size: 1000%; float: left; margin: 0; padding: 0; }
div#fl_d { position: relative; top: 0px; width: 200px; }
div#varijante { clear: both; }
span#varijante a { color: orange; margin: 0 5px; text-decoration: none; }
span#varijante a[selected='1'] { text-decoration: underline; }
table#t { position: relative; top: 50px; }
div#tj0 { float: left; margin-right: 60px; }
div#tj1 { float: left; margin-right: 30px; }
div.cb { clear: both; }
"
end

def ozn?(predmet, eventi_d) # oznaci sat u danu ako je u eventima tog dana
  eventi_d.compact.each{|e|
    return "1" if !predmet.nil? &&
          (e[/^(\w+) /,1].downcase rescue "") == predmet.downcase
    # return "_dz" if e =~ / dz$/i
    # puts "_dz: #{e}" if e =~ / dz$/i
  }
  false
end

def boja(s, i, p="") # dan, sat, txt
  # return "gray" if %w(uto sri).include?(s) && (2..4).include?(i)
  case p
  when /--/
    return "empty"
  when /SRO/, /TZK/
    return "wgray"
  end
  nil
end

get '/test' do
  haml :test
end

__END__

@@ras_nije_podesen
%h2.err Raspored nije podesen za ovaj razred ...
%p
  %a{:href=>"/"} < Svi razredi

@@razredi
%center
  %table#t
    %tr
      %td
        %div#fl_d
          %h1.raz_naslov R
      %td
        %ul.svi_razredi
          - for r in @razredi
            %li
              %a{:href=>"/#{r}"}= raz r

@@ras_tbl
%table{:border=>2, :id=>"tbl_ras"}
  %tr
    / dani
    %th{:width=>20} &nbsp;
    - for s in DANI.first(5).map{|x| x.capitalize}
      %th{:width=>80, :class=>"gray#{(DANI[(DateTime.now.strftime("%w").to_i+6)%7] == s.downcase) ? " uline" : "" if @tj==0}"}= "#{s}"
  %tr
    / datumi
    %th &nbsp;
    - for i in 1..5
      %th= "#{(prvi_dan_tj+i+@tj*7).strftime "%d.%m."}"
  %tr
    / GCal eventi
    %th Kal.
    - for i in 1..5
      %th{:valign=>"top", :class=>"events_l"}
        %ul
          - for x in (@eventi[DANI[i-1]] rescue [])
            - hd = (!x[1].nil? && !x[1].empty?)
            %li{:class=>"gcal_event_li#{hd ? " hasdesc" : ""}", :title=>(hd ? x[1].split("\n").join("; ") : nil)}= "#{hd ? "+" : "-"} #{x.first}"

  - smj = smjena(DateTime.now+@tj*7)
  - for i in 0..8
    %tr
      %td{:class=>"gray"}= "#{i}."
      - for s in DANI.first(5)
        - idx = smj==0 ? i : 8-i
        - x = ((@ras[idx] || {})[s] || "").upcase
        - klase = []
        - klase << boja(s, i, x)
        - if !x.nil? && oz=ozn?(x[/(\w+)/,1], @eventi[s].collect{|e| e[0]})
          - klase << "ozn#{oz}"
        - if @tj == 0
          - t = (koji_sat?(Time.now) || [0, 0])
          - sada=nil; sada = (t[1] rescue nil) if DANI[(DateTime.now.strftime("%w").to_i-1)%7] == s && t[0]==(smjena(DateTime.now)+1)
          - klase << "tek_sat" if sada==i
          - klase << ((DANI[(DateTime.now.strftime("%w").to_i-1)%7] == s) ? "danas" : "")
        %td{:class=>klase.join(' ')}= (x =~ /\, /) ? "#{x.gsub(/\, /, ' (')})" : x if !x.nil?

@@razred
%h1= "Razred: #{raz @str}"

%div#rasporedi
  - for ntj in 0..@n_tj-1
    %div{:id=>"tj#{ntj}"}= ras_html(@tbls[ntj], ntj, @ev[ntj])

%div.cb

%p
  %a{:href=>"/"} < Svi razredi

- B.close

@@layout
!!! Transitional
%html{:xmlns => "http://www.w3.org/1999/xhtml"}
  %head
    %meta{:content => "text/html; charset=iso-8859-1", "http-equiv" => "Content-Type"}/
    %title= (@title || "Raspored#{@t_nast || "App"}")
    %link{:href => "/style.css", :rel => "stylesheet", :type => "text/css"}/
    %script{:src => "http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js", :type => "text/javascript"}
    %script{:type => "text/javascript"}
      = '$(function(){$("table#tbl_ras tr td, table#tbl_ras th.events_l").hover(function(){$(this).addClass("highlight");},function(){$(this).removeClass("highlight");})})'
  %body
    %div{:id=>"container"}

      = yield

