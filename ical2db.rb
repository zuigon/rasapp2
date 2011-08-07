require "rubygems"
require "./gcal-lib.rb"
# gem "ruby-mysql", "= 2.9.3"
# require "mysql"

class Ical2db
  def initialize(cal, mhost, muser, mpass, mdb, raz_id=0)
    @cal = CalendarReader::Calendar.new cal
    @c = Mysql.real_connect mhost, muser, mpass, mdb
    @raz_id = raz_id
  end

  def sync()
    puts "iCal2DB DEPRECATED"
    return

    inserted, changed, skipped, deleted = *[0]*4
    cols = %w(raz_id uid txt dsc dan)

    start = Time.now

    @cal.events.collect{|e|
      s = [
        @raz_id,
        e.uid || "",
        e.summary || "",
        (e.description || "").gsub(/\\\\/, ''),
        e.start_time.strftime("%Y-%m-%d") || ""
      ]
      t = "select #{cols.join ", "} from eventi where uid = '#{s[1]}' limit 1"
      if (o = @c.query(t)).count == 0
        @c.query "Insert Into eventi (#{cols.join ", "}) values (#{s[0]}, '#{s[1]}', '#{s[2]}', '#{s[3]}', '#{s[4]}')"
        inserted+=1
      else
        o = o.first

        sets = []
        cols.each_with_index do |n, i|
          sets<<"#{n}='#{s[i]}'" if s[i].to_s.gsub(/\\\\?/, '') != o[i]
        end

        if !sets.empty?
          q = "update eventi set #{sets.join ", "} where uid = '#{s[1]}'"
          @c.query q
          changed+=1
        else
          skipped+=1
        end
      end
    }

    ev_uids = @cal.events.collect{|x| x.uid}
    @c.query("select uid from eventi").each do |row|
      if !ev_uids.find{|e| e==row[0]}
        @c.query("delete from eventi where uid='#{row[0]}'")
        deleted+=1
      end
    end

    "[  inserted: #{inserted}   changed: #{changed}   skipped: #{skipped}   deleted: #{deleted}  ]\n"+sprintf("TIME: %.3f\n", Time.now-start)
  end
end

if __FILE__ == $0
  cl = Ical2db.new "file:///Users/bkrsta/Projects/raspored-app2/basic.ics", "192.168.1.250", "root", "bkrsta", "ras2_1", "2009_a"
  puts cl.sync
end
