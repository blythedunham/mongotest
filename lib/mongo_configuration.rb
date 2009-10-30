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

  def setup( options = {} )
    load_configuration_file
    self.connection.update( options )
    connect
  end

  def connect!
    if !disabled?

      #otherwise default to the the host specified in database.yml
      MongoMapper.connection = Mongo::Connection.new(
        host, port, connection_options || {}
      )

      MongoMapper.database = database

      self.host = MongoMapper.database.host
      self.port = MongoMapper.database.port
    end
    connected?
  end

  def connect
    connect!
    true
  rescue => e
    Rails.logger.error "FAILED TO CONNECT TO MONGO #{ self.connection.inspect }"
    return false
  end

  def connected?
    !!(MongoMapper.connection && MongoMapper.database)
  rescue => e
    return false
  end

  def disabled?; disabled; end

end

class MongoConfiguration
  include Singleton
  extend MongoConfigurationSupport

  class_inheritable_accessor :config_file
  self.config_file = File.join( Rails.root, 'config', 'mongodb.yml' )

  class_inheritable_hash      :connection
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
