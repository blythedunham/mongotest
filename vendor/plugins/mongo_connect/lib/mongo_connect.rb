require File.dirname(__FILE__) + '/configie/base.rb'
require File.dirname(__FILE__) + '/connectors.rb'

class MongoConnect < Configie::Singleton
  unless defined?( DEFAULT_DNA_FILE )
    DEFAULT_DNA_FILE = '/etc/chef/dna.json'
  end

  self.default_configuration = {
    :host => Rails.configuration.database_configuration[RAILS_ENV]['host'],
    :port => 27017.to_s,
    :database => "#{File.basename(Rails.root)}_#{Rails.env}",
    :enabled => true,
    :connection_options => {
      :auto_reconnect => true,
      :logger => ( Rails.logger if Rails.env != 'production' )
    },
    :config_file => [
      [File.join( Rails.root, 'config', 'mongodb.yml' ), { :env => true }]
    ],
    :dna => {
      :file => Rails.env == 'production' ? DEFAULT_DNA_FILE : nil,
      :enabled => false,
      :instance_name => 'mongodb',
      :role => :utility_slices
    },
  }

  def setup!( options = {} )
    monitor.synchronize do
      configure!( options )
      connect!( true )
    end
  rescue => e
    log :error, "Unable to configure mongodb connector"
    raise e
  end

  def connect!( reconnect = false )
    monitor.synchronize do
      if !enabled?
        log :info, "Mongo connection disabled."

      elsif !connected? || !!reconnect
        log_connection_message
        connectors.each { |con| con.connect( self.configuration_options ) }

      end
      return enabled? && connected?
    end
  rescue => e
    log :error, "Unable to connect to mongodb. Is it running? #{e}"
    raise e
  end

  def connect(*args);         safe_invoke{ connect!(*args) }; end
  def setup(*args);           safe_invoke{ setup!(*args) };    end
  def connected?;             safe_invoke{ connectors.all?{|con| con.connected? } }; end
  def driver_connection;      safe_invoke( nil ) { connectors.first.connection }; end
  def enabled?; !!preference( :enabled ); end
  def reconnect; connect( true ); end

  def connectors
    monitor.synchronize do
      @connectors ||= MongoConnector.connector_instances( preference(:connectors), true )
    end
  end

  def connector_for( name )
    connectors.detect{|c| c.name == name.to_s }
  end

  protected

  def reset
    super
    @connectors = nil
  end

  #def connection_defaults; CONNECTION_DEFAULTS; end

  # Grab the configuration options which merges +options+ with
  # 1. default options
  # 2. dna.json file if :read_dna => true
  # 3. config_file settings specified by :config_file. Set to false to disable
  def additional_configuration_options( merged_options, preferences )
    preferences.unshift( load_dna_config( merged_options ) )
    super( merged_options, preferences )
  end

  def load_dna_config( options = nil )#:nodoc:
    options ||= self.configuration_options || {}

    # if set to true, inherit from the default_configuration
    options[:dna] = default_configuration[:dna].merge( :enabled => true ) if options[:dna] == true
    return unless options[:dna] && options[:dna][:enable] && options[:dna][:file]

    # Read the dna file
    dna_hostname = load_config_file(
      options[:dna][ :file ],
      :key_chain => [ Rails.env, options[:dna][:role], options[:dna][:instance_name], :hostname ]
    )

    { :host => dna_hostname } if dna_hostname
  end

  def log_connection_message
    msg = "MongoDB connecting.... "
    msg << %w( host port database connectors).collect{ |a| "#{a}:#{preference(a)}" }.join(' ')
    log :info, msg
  end

end

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      MongoConfiguration.reconnect
      # Call db.connect_to_master to reconnect here
    end
  end
end