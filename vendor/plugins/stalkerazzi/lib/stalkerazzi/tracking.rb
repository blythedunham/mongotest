module Stalkerazzi
  module Tracking
    def self.included( base )
      base.class_eval do

        class_inheritable_accessor :logger
        self.logger = (ActiveRecord::Base.logger if Rails.env != 'production')

        class_inheritable_hash :stalkerazzi_options
        self.stalkerazzi_options = {
          :enabled => true,
          :handle_exception => true
        }

        class_inheritable_hash :default_tracked_fields
        self.default_tracked_fields = {
          :action => :action_name,
          :controller => :controller_name,
          :path => :path
        }

        extend( ClassMethods )
      end
    end

    module ClassMethods
      # Configure stalkerazzi
      def configure( options={} )
        options.symbolize_keys!

        self.default_tracked_fields = options.delete( :fields ) if options.has_key?( :fields )
        self.logger = options.delete( :logger ) if options.has_key?( :logger )
        self.stalkerazzi_options.update( options )
      end
    end

    # Store the data with the specified storage mechanism.
    # Storage can be either a Proc or a symbol, string or class
    # Storage classes implement +store_tracked_event+
    def store_data( data, options = {}, storage = nil)
      storage ||= storage_class( options[ :storage ] )
      log( "Storing data with #{storage.inspect}\n  #{data.inspect}")

      if storage.is_a?( Proc )
        storage.call( data, self )

      elsif storage
        storage.store_tracked_event( data, self )
      end

    end



    # Track events by saving
    # <tt>:data</tt> - (Optional) A hash or a proc that returns a hash of the
    #    raw  data. When not specified, +tracked_event_data+ is invoked to format
    #    the data
    # ===Options
    # <tt>:storage</tt> - The class name of the ActiveRecord, Document, or other object
    #    used to store the data. Defaults +Logger+
    # <tt>:fields</tt> - Additional field mappings
    # <tt>:default_data</tt> - Default the fields specified here
    # <tt>:only</tt>
    def track_event( data = {}, options = {} )
      track_event!( data, options )
    rescue => e
      handle_tracking_exception e
    end

    # Track event for an object.
    # This allows the :with parameter to be a Proc or Method on the object
    def track_event_for_object( object, options )#:nodoc:
      return unless enabled?
      with = options.delete( :with )
      data = case with
        when Proc then with.call( object )
        when String, Symbol then object.send( with )
        when Hash then with
      end || {}
      track_event( data, options )
    end

    def enabled?
      !!stalkerazzi_options[:enabled]
    end

    protected

    def log( message, level = :debug )
      puts message if Rails.env == 'development'
      logger.send( level, message ) if logger
    end


    # Track data without handling exceptions
    def track_event!( data = {}, options = {})#:nodoc:
      return unless enabled?
      transformed_data = transform_data( data, options )
      store_data( transformed_data, options )
    end
 
    def log_exception(exception, callstack = false)
      msg = "Stalkerazzi exception: #{exception}"
      msg << "\n #{exception.backtrace.to_yaml}" if callstack
      log msg, :error
    end

    def handle_tracking_exception( exception )
      case stalkerazzi_options[:handle_exception]
        when Proc then stalkerazzi_options[:handle_exception].call( exception )
        when TrueClass then log_exception( exception, true )
        else raise exception
      end
    end

    # Find the storage class which implements method +store_tracked_event+
    # from a string, symbol or class
    def storage_class( class_name )
      name = class_name || stalkerazzi_options[ :storage ]
      name = name.to_s.classify.constantize if name.is_a?( String ) || name.is_a?( Symbol )
      name
    end

    def tracked_fields( options ={} )
      storage = storage_class( options[ :storage ] )

      tracked_statistics = unless storage.try( :tracked_fields ).blank?
        storage.tracked_fields
      else
        self.default_tracked_fields || {}
      end.merge( options[:fields] || {} )
    end

    # Return a hash with the data to be tracked
    # +data+ - A hash or a proc that returns a hash containing prepopulated data.
    # The request and controller data will be merged with this hash.
    # === Options
    # * <tt>:except</tt> - exclude this data
    # * <tt>:only</tt> - include this field
    # * <tt>:fields</tt> - additional tracked statistics
    def transform_data( data = {}, options = {} )

      event_data = if data.is_a?( Proc )
        data.call( self, options )
      else
        data || {}
      end.symbolize_keys

      tracked_statistics = tracked_fields( options )

      key_names = tracked_statistics.keys

      log "TRACKING: #{tracked_statistics.inspect}"
      if options[:only]
        options.delete(:except)
        key_names = key_names & Array(options[:only]).collect { |n| n.to_s }

      elsif options[:except]
        options[:except] = Array(options[:except])
        key_names = key_names - options[:except].collect { |n| n.to_s }
      end

      key_names.each do |name|
        next if event_data.has_key?( name.to_sym )
        event_data[ name.to_sym ] = tracked_event_field_data(
          name, tracked_statistics[name], options
        )
      end
      event_data
    end

    def tracked_event_field_data( name, tracked_method, options = {})
      if tracked_method.is_a?( Proc )
        tracked_method.call( self, options )

      elsif respond_to?( tracked_method )
        send( tracked_method )

      elsif request.respond_to?( tracked_method )
        request.send( tracked_method )

      else
        name
      end
    end
  end
end
