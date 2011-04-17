%w[rubygems active_support/core_ext/numeric/time.rb open-uri ./gcal-lib ./ical2db ./db-lib].each{|x| require x}
if RUBY_VERSION =~ /^1.8/
  require "system_timer"
else
  require "timeout"
end

def sync_cals(timeout=600)
  urls = []
  # f = File.read("urls.txt")
  # f.each{|l| urls << (l.scan(/(\d\d\d\d_[a-z]):? *(.+)\n?/).first rescue break) }
  # urls = urls.compact

  ss = SeqConn.new *(File.readlines("db.conf").first[/(.+)\n?/,1].split(":")[0..3])
  ss.open
  q = ss.query "select gen, raz, calurl from razredi where calurl != ''"
  while row = q.first; urls << ["#{row[0]}_#{row[1]}", row[2]]; end

  b = SeqConn.new *(File.readlines("db.conf").first[/(.+)\n?/,1].split(":")[0..3])

  blo = Proc.new {
    urls.each{|d|
      x = File.readlines("db.conf").first[/(.+)\n?/,1].split(":")[0..3] + [b.raz_id(*d[0].split("_"))]
      cl = Ical2db.new d[1], *x # url, host, user, pass, db, raz_id
      puts "Sinkroniziram razred '#{d[0]}'\nCAL_URL: '#{d[1]}'"
      cl.sync
    }
  }

  b.open
  begin
    if RUBY_VERSION =~ /^1.8/
      SystemTimer.timeout_after(timeout.seconds){ blo.call }
    else
      timeout(timeout){ blo.call }
    end
  rescue Timeout::Error
    puts "sync_cals() timeout! (#{timeout} sec.)"
  end
  b.close
end

if __FILE__ == $0
  sync_cals()
end
