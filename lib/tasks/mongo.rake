
mongo_driver_bin  = Dir.glob(File.join(Rails.root, 'vendor/gems/mongo-0.*/bin')).first

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
end
