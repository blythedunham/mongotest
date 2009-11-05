module MongoConfigurationSupport

  def self.extended( base )
    %w(disabled host port database connection_options).each do |method|

      base.class_eval <<-EOS, __FILE__, __LINE__
        def self.#{method}; self.connection[ :#{method} ]; end
        def self.#{method}=(value)
          self.connection[ :#{method} ] = value
        end
      EOS

      base.send(:delegate, method, "#{method}=", :to => base )
    end
    base.send( :include,  self )
  end

  def load_configuration_file( file_name = nil )
    # first read from the mongodb.yml if it exists
    file = file_name || self.config_file

    if file && File.exists?( file )
      yaml_connection = YAML.load( File.read( file ) )[ Rails.env ]
      self.connection.update( yaml_connection.symbolize_keys ) if yaml_connection
    end
  end

  def setup!( options = {} )
    load_configuration_file
    self.connection.update( options )
    self.orms = available_orms if self.orms.blank?
    connect!
  end

  def setup( options = {} )
    setup!( options )
    true
  rescue => e
    false
  end

  def available_orms
    orms = []
    orms << :mongo_mapper if defined?( MongoMapper )
    orms << :mongo_record if defined?( MongoRecord )
    orms << :mongo if defined?( Mongo::Connection ) && orms.empty?
    orms
  end

  def new_mongo_connection
    Mongo::Connection.new(
      host, port, connection_options || {}
    )
  end

  def connect_mongo_mapper
    MongoMapper.connection = new_mongo_connection
    MongoMapper.database = database
    self.host = MongoMapper.database.host
    self.port = MongoMapper.database.port
  end

  def connect_mongo_record
    MongoRecord::Base.connection = new_mongo_connection.db( database )
  end

  def connect_mongo
    $mongodb = new_mongo_connection
  end

  def mongo_mapper_connected?
    !!(mongo_mapper_connection && MongoMapper.database)
  end

  def mongo_mapper_connection
    MongoMapper.connection 
  end

  def mongo_record_connection
    MongoRecord::Base.connection
  end

  def mongo_connection
    $mongodb
  end

  def connect!
    unless disabled?
      log :info, "Mongo connecting.... #{self.host||'localhost'} on port:#{self.port || 'default' }"
      [self.orms].flatten.each { |orm| send( "connect_#{orm}" ) }
    else
      log :info, "Mongo connection disabled."
    end
    connected?
  end

  def connect
    connect!
  rescue => e
    log :error, "Unable to connect to mongodb with: #{ self.connection.inspect }\n  #{e}"
    return false
  end

  def connected?
    orms.all?{ |orm|
      if respond_to? "#{orm}_connected?"
        send( "#{orm}_connected?" )
      else
        !!(send( "#{orm}_connection"))
      end
    }
  rescue => e
    log :error, "Mongodb not connected: #{e.to_s} #{e.backtrace.to_yaml}"
    return false
  end

  def driver_connection( orm_name = nil )
    send "#{orm_name||self.orms.first}_connection"
  rescue => e
    nil
  end

  def log( level, message )
    Rails.logger.send level, message if Rails.logger
  end
  
  def disabled?; disabled; end

end

class MongoConfiguration
  include Singleton
  extend MongoConfigurationSupport

  class_inheritable_accessor :config_file
  self.config_file = File.join( Rails.root, 'config', 'mongodb.yml' )

  class_inheritable_accessor :orms

  class_inheritable_hash     :connection
  self.connection = {
    :host => Rails.configuration.database_configuration[RAILS_ENV]['host'],
    :database => "mongotest-#{Rails.env}",
    :disabled => false,
    :connection_options => { 
      :auto_reconnect => true,
      :logger => Rails.logger
    }
  }
  
end
