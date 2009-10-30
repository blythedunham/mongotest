
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

namespace :mongo do

  desc "Prints out the connection"
  task :connection => :environment do
    puts MongoConfiguration.connection.inspect
  end

  desc "Run the benchmarks from the mongo driver"
  task :driver_benchmarks => :environment do
    script_file = File.join( mongo_driver_bin, 'standard_benchmark')
    command = "export MONGO_RUBY_DRIVER_HOST=#{MongoConfiguration.host} && #{script_file}"
    puts command
    unless ENV['DRY_RUN']
      puts system(command)
    end
  end

  desc "Drop mongo database rake mongo:drop DB=some_db"
  task :drop => :environment do
    database = ENV['DB']
    database ||= MongoConfiguration.database if Rails.env != 'production'

    raise "Specify database: rake mongo:drop DB=some_db" unless database
    connection = MongoConfiguration.driver_connection
    connection.drop_database( database )
 
  end


  desc "Benchmark orms"
  task :benchmark_orm => :environment do
    @mongo_connection = MongoConfiguration.driver_connection.
      db( MongoConfiguration.database ).collection('mongo-statistics')

    n = ( ENV['TIMES'] || 100) .to_i
    ms = Benchmark.bm( 30 ) do |x|
      x.report( " Mongo:Connection" )  { n.times { @mongo_connection.insert( simple_stats ) } }
      x.report( " MongoMapper:Blank" ) { n.times { Stalkerazzi::Trackers::Mongo::Blank.create!( simple_stats ) } }
      x.report( " MongoMapper:EmbeddedDocument" ) { n.times { Stalkerazzi::Trackers::Mongo::EmbeddedStatistic.create!( simple_stats ) } }
      x.report( " MongoMapper:Statistic" ) { n.times { Stalkerazzi::Trackers::Mongo::Statistic.create!( simple_stats ) } }
    end
  end

end
