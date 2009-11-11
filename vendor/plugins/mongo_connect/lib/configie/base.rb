require File.dirname(__FILE__) + '/singleton.rb'
require File.dirname(__FILE__) + '/file_reader.rb'
require File.dirname(__FILE__) + '/option_accessor.rb'

module Configie
  class Base
    include FileReader
    include OptionAccessor

    class_inheritable_accessor :key_format
    self.key_format = :symbolize

    class_inheritable_accessor :merge_method
    self.merge_method = :deep_merge!

    class_inheritable_hash :default_configuration
    self.default_configuration = HashWithIndifferentAccess.new

    def self.configure( options = {} )
      new.configure( options )
    end

    def self.configure!( options = {} )
      new.configure!( options )
    end

    # Reapply the configuration settings by layering
    # 1. default configuration
    # 2. Config files
    # 3. new options
    def configure!( new_settings = {} )
      combined_settings = build_configuration( new_settings )
      monitor.synchronize do
        reset
        @configuration_options = combined_settings
      end
    end

    def configure(*a); safe_invoke { configure!(*a) }; end

    # Merge options onto the existing configuration options
    # configuration.merge_configurations( {}, {:a => 5} )
    def merge!( *configs )
      configs = [configs] unless configs.is_a?( Array )
      monitor.synchronize do
        configs.shift( self.configuration_options )
        self.connection_options = merge( *configs )
      end
    end

    # merge the configuration files together
    def merge( *configs )
      merge_configurations( configs, {
        :key_format => key_format,
        :merge_method => merge_method
      })
    end

    # Load the config files preferences
    def config_file_preferences( options = {} )
      config_files = preference( :config_file, options )
      config_files = [config_files] if config_files && !config_files.is_a?( Array )
      load_config_files( *(config_files << options) ) if config_files
    end

    def format_key( key )
      safe_invoke( nil ) { key_format == :stringify ? key.to_s : key.to_sym  }
    end

    protected
    # invoke a method, catch errors and return the ret_value
    # +error_value+ - the data or proc that returns the data when an error occurs
    def safe_invoke( error_value = false )#:nodoc:
      yield
    rescue => e
      error_value.is_a?( Proc ) ? error_value.call( e ) : error_value
    end

    def build_configuration( new_settings )
      merged_options = merge( default_configuration, new_settings )
      preferences = additional_configuration_options( merged_options, [] )
      preferences.unshift( default_configuration )
      preferences << new_settings

      merge( *(preferences.compact!) )
    end

    def additional_configuration_options( merged_options, preferences )
      preferences << config_file_preferences( merged_options )
      preferences
    end

    def reset
      @configuration_options = nil
    end

    def log( level, message )
      Rails.logger.send level, message if defined?( Rails ) and Rails.logger
    end

  end

  class Singleton < Base
    include ::SingletonWithDelegation
  end
end
