
mongo_driver_bin  = Dir.glob(File.join(Rails.root, 'vendor/gems/mongo-0.*/bin')).first

def simple_stats( options = {} )
  {
    :params => [{:param1 => 'd'}],
    :event_type => "super_#{rand(6666666)}",
    :user_id => rand(400),
    :path => 'http://asdf.grapse.com/api/actions?grapes=true',
    :action => "action_#{rand(50)}"
  }
end

def mongo_benchmark_connection
  db_name = ENV['DB'] || 'benchmark-orm'
  connection = MongoConnect.driver_connection
  connection.drop_database( db_name )

  MongoMapper.database = db_name
  MongoRecord::Base.connection = connection.db( db_name )

  connection.db( db_name )
end

namespace :mongo do

  desc "Prints out the connection"
  task :connection => :environment do
    puts MongoConnect.connection.inspect
  end
  desc "Drop mongo database rake mongo:drop DB=some_db"
  task :drop => :environment do
    database = ENV['DB']
    database ||= MongoConnect.database if Rails.env != 'production'

    raise "Specify database: rake mongo:drop DB=some_db" unless database
    connection = MongoConnect.driver_connection
    connection.drop_database( database )

  end
  namespace :benchmark do
    desc "Run the benchmarks from the mongo driver"
    task :driver => :environment do
      script_file = File.join( mongo_driver_bin, 'standard_benchmark')
      command = "export MONGO_RUBY_DRIVER_HOST=#{MongoConnect.host} && #{script_file}"
      puts command
      unless ENV['DRY_RUN']
        puts system(command)
      end
    end


    desc "Benchmark orms DB=dbname TIMES=100"
    task :orm => :environment do
      n = ( ENV['TIMES'] || 100) .to_i
      ms = Benchmark.bm( 30 ) do |x|
        @db = mongo_benchmark_connection
        @collection = @db.collection('driver_statistics_cached')
        x.report( "Mongo collection" )  { n.times { @collection.insert( simple_stats ) } }
        x.report( "Mongo db" )  { n.times { @db.collection('driver_statistics').insert( simple_stats ) } }

        mongo_benchmark_connection
        x.report( "MongoMapper:Blank" ) { n.times { Stalkerazzi::Trackers::Mongo::Blank.create!( simple_stats ) } }
        x.report( "MongoMapper:EmbeddedDocument" ) { n.times { Stalkerazzi::Trackers::Mongo::EmbeddedStatistic.create!( simple_stats ) } }
        x.report( "MongoMapper:Statistic" ) { n.times { Stalkerazzi::Trackers::Mongo::Statistic.create!( simple_stats ) } }

        mongo_benchmark_connection
        x.report( "MongoRecord:Statistic" ) { n.times { Stalkerazzi::Trackers::MongoRecord::Statistic.create( simple_stats ) } }
        x.report( "MongoRecord:Blank" ) { n.times { Stalkerazzi::Trackers::MongoRecord::Blank.create( simple_stats ) } }
        x.report( "MongoRecord:EmbeddedDocument" ) { n.times { Stalkerazzi::Trackers::MongoRecord::EmbeddedStatistic.create( simple_stats ) } }
      end
    end
  end
end
