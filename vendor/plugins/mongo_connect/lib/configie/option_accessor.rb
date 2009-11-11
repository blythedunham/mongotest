module Configie
  module OptionAccessor
    def monitor; @monitor||= Monitor.new; end

    def configuration_options=( value )
      monitor.synchronize { @configuration_options = format_keys( value || {} ) }
    end

    def configuration_options
      @configuration_options.dup
    rescue => e
      nil
    end

    # define methods
    def define_getters_and_setters( method )#:nodoc:
      monitor.synchronize do
        self.class.class_eval <<-EOS, __FILE__, __LINE__
          def #{method}; preference( :#{method} ); end
          def #{method}=(value); set_preference( :#{method}, value ); end
        EOS
      end
    end

    # Returns the value of the preference (case insensitive)
    # +key+ - the key name of the preference
    # +config_options+ - Defaults to current config options, but another hash can
    #  be passed in
    def preference( key, config_options = nil )
      (config_options || @configuration_options || {})[ format_key( key) ]
    end

    # Set the prefernce for +key+ with +value+
    def set_preference(key, value)
      monitor.synchronize do
        @configuration_options||= format_hash_keys
        @configuration_options[ format_key( key ) ] = value
      end
    end

    def format_key( key ); key; end

    # delegate missing methods to the connection hash
    def method_missing( method, *arguments, &block )#:nodoc:
      root_method = method.to_s.gsub(/=$/, '')
      if preference( root_method )
        define_getters_and_setters( root_method )
        send( method, *arguments, &block)
      end
    rescue => e
      super( method, *arguments, &block )
    end
  end
end
