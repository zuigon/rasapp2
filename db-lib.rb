require "sequel"

# DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://my.db')
DB = Sequel.sqlite

DB.create_table :eventi do
  primary_key :id
  Integer :raz_id
  String :uid
  String :txt
  String :dsc
  Date :dan
  String :predmet
  Integer :tip
end

DB.create_table :rasporedi do
  primary_key :id
  Integer :raz_id
  Time :start_date
  Integer :sat, size: 100
  String :pon, size: 100
  String :uto, size: 100
  String :sri, size: 100
  String :cet, size: 100
  String :pet, size: 100
  String :sub, size: 100
end

DB.create_table :razredi do
  primary_key :id
  Integer :skola_id
  String :raz, size: 4
  String :gen, size: 10
  String :calurl, size: 200
end

DB.create_table :skole do
  primary_key :id
  String :naziv, size: 64
  String :caladdr
end

DB[:razredi].insert skola_id: 0, raz: 'a', gen: '2009'
DB[:rasporedi].insert raz_id: 1, sat: 1, pon: 'a'

class SeqConn
  def initialize(*opts)
    @c = nil
    @d = {}
  end
  def open
  end
  def close
  end
  def razredi
    DB[:razredi].map{|x|
      [x[:gen]+'_'+x[:raz]]
    }
  end
  def raspored(raz_id)
    raise "raz_id must be int!" if ! raz_id =~ /^\d+$/
    h={}; i=0
    DB[:rasporedi].where(raz_id: raz_id).order(:sat).map{|x|
      [x[:sat], x[:pon], x[:uto], x[:sri], x[:cet], x[:pet], x[:sub]]
    }.each{|x| h[i]=x; i+=1}
    return h
  end
  def eventi(raz_id, tj)
    raise "raz_id must be int!" if ! raz_id =~ /^\d+$/
    raise "tj must be int!" if ! tj =~ /^\d+$/
    # DB[:eventi].where(
    #   raz_id: raz_id, :week.sql_function(:dan) => "(week(date(now())-1)+#{tj})"
    # ).select{ [weekday(dan), txt, dsc] }
    ['0', 'TODO', nil]
  end
  def raz_id(gen, raz)
    DB[:razredi].where(gen: gen, raz: raz).select(:id).limit(1).first[:id]
  end
end
