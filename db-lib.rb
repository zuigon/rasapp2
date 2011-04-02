gem "ruby-mysql", "= 2.9.3"
require "mysql"

class SeqConn # MySQL client
  def initialize(host, user, passw, db)
    @data = [host, user, passw, db]
    @c = nil
  end
  def open
    @c = Mysql.real_connect *@data
  end
  def close
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
    raise "raz_id must be int!" if ! raz_id =~ /^\d+$/
    raise "tj must be int!" if ! tj =~ /^\d+$/
    @c.query("select weekday(dan), txt, dsc from eventi where raz_id=#{raz_id} and week(dan)=(week(date(now())-1)+#{tj});").to_a
  end
  def raz_id(gen, raz)
    r = @c.query("select id from razredi where gen='#{gen}' and raz='#{raz}' limit 1;").first[0]
  end
  def query(str)
    @c.query str
  end
end
