class MongoConnector
  def new_mongo_connection( options = {})
    options ||={}
    Mongo::Connection.new(
      options[:host], options[:port], options[:connection_options] || {}
    )
  end
  def reconnect( options = {} )
    self.connection = nil
    connect( options )
  end

  def name; self.class.to_s.gsub('Connector').under_score; end

  def connected?
    !!connection
  rescue
    false
  end

  def host; connection.host; end
  def port; connection.port; end

  def self.available_connectors
    connectors = []
    connectors << :mongo_mapper if defined?( MongoMapper )
    connectors << :mongo_record if defined?( MongoRecord )
    connectors << :mongo_driver if defined?( Mongo::Connection ) && connectors.empty?
    connectors
  end

  def self.connector( connector )
    return connector if connector.is_a?( MongoConnector )
    (connector.to_s.classify + 'Connector').constantize.new
  end

  def self.connector_instances( connectors, search = false )
    connectors = available_connectors if connectors.blank? && search
    [connectors].flatten.collect{ |c| MongoConnector.connector( c ) }
  end
end



class MongoDriverConnector < MongoConnector
  def connect( options = {} )
    Thread.current[:mongo_connection] ||= Mongo::Configurator.new_mongo_connection( options )
    [ host, port ]
  end

  def connection
    Thread.current[:mongo_connection]
  end
end



class MongoRecordConnector < MongoConnector
  def connect( options = {})
    MongoRecord::Base.connection = new_mongo_connection( options ).db( options[:database] || options['database'] )
    [ host, port ]
  end
  def connection; MongoRecord::Base.connection; end
end



class MongoMapperConnector < MongoConnector
  def connect( options = {})
    MongoMapper.connection = new_mongo_connection( options )
    MongoMapper.database = options[:database]
    [ host, port ]
  rescue => e
    puts e.backtrace.to_yaml
  end

  def connected?
    !!(connection && MongoMapper.database)
  end
  def connection; MongoMapper.connection; end
  def database; MongoMapper.database; end
  def host; database.host; end
  def port; database.port; end
end
