module Stalkerazzi
  module Tracking
    def self.included( base )
      base.class_eval do
        class_inheritable_accessor :logger
        self.logger = nil

        class_inheritable_hash :stalkerazzi_options
        self.stalkerazzi_options = {
          :logger => (ActiveRecord::Base.logger if Rails.env != 'production')
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
    def store_data( data, options = {})
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
      with = options.delete( :with )
      data = case with
        when Proc then with.call( object )
        when String, Symbol then object.send( with )
        when Hash then with
      end || {}
      track_event( data, options )
    end

    protected

    def log( message, level = :debug )
      puts message if Rails.env == 'development'
      logger.send( :level, message ) if logger
    end


    # Track data without handling exceptions
    def track_event!( data = {}, options = {})#:nodoc:
      transformed_data = transform_data( data, options )
      store_data( transformed_data, options )
    end
    def log_exception(exception, callstack = false)
      msg = "Stalkerazzi exception: #{exception}"
      msg << "\n #{exception.backtrace.to_yaml}" if callstack
      puts msg
      logger.error( msg ) if logger
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

    # Track a statistic from the controller
    # *options* - can be a proc that returns the data to use or a hash specifying
    #   the parameters to generate the hash data
    # === Options
    # * <tt>:except</tt> - exclude this data
    # * <tt>:only</tt> - include this field
    # * <tt>:default</tt> - the default data to start with
    # * <tt>:fields</tt> - additional tracked statistics

    # Generate a statistic hash
    # === Options
    # * <tt>:except</tt> - exclude this data
    # * <tt>:only</tt> - include this field
    # * <tt>:default_data </tt> - a hash of defaulted data
    # * <tt>:fields</tt> - additional tracked statistics
    def transform_data( data = {}, options = {} )

      event_data = if data.is_a?( Proc )
        data.call( self, options )
      else
        data || {}
      end.symbolize_keys

      tracked_statistics = tracked_fields( options )

      key_names = tracked_statistics.keys

      puts "TRACKING: #{tracked_statistics.inspect}"
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
        send( tracked_method ).to_s

      elsif request.respond_to?( tracked_method )
        request.send( tracked_method ).to_s

      else
        name
      end
    end
  end

  module TrackingCurrentController
    #predefined methods
    def headers
      request.headers.reject { |k,v| !v.is_a?( String ) } if request.try( :headers )
    end

    def current_user
      controller.try(:current_user) if controller.respond_to?(:current_user)
    end

    def controller_name;   params[:controller].to_s; end
    def timestamp;         Time.now.utc; end
    def current_user_id;   current_user.try(:to_param); end

    %w(user_agent referer referrer remote_addr path_info).each do |method|
      module_eval <<-END_SRC, __FILE__, __LINE__
        def #{method}; request.try :#{method}; end
      END_SRC
    end

    %w(session request params action_name).each do |method|
      module_eval "def #{method}; controller.try(:#{method}); end ", __FILE__, __LINE__
    end

    def with_controller( controller, &block )
      self.controller = controller
      yield
    ensure
      self.controller = nil
    end

    def controller
      Thread.current[:stalkerazzi_controller]
    end

    def controller=(controller)
      Thread.current[:stalkerazzi_controller] = controller
    end

    def track_event_with_controller( controller, data = {}, options = {} )
      with_controller( self ) { track_event_for_object( self, options ) }
    end

    private
    def method_missing(method, *arguments, &block)
      return if controller.nil?
      controller.__send__(method, *arguments, &block)
    end

     #           :user_agent => env['HTTP_USER_AGENT'],
     #       :language => env['HTTP_ACCEPT_LANGUAGE'],
     #       :path => env['PATH_INFO'],
     #       :ip => env['REMOTE_ADDR'],
     #       :referer => env['HTTP_REFERER']
  end
end

module Stalkerazzi
  class Tracker
    include Singleton
    include Tracking
    include TrackingCurrentController

    public
    class << self
      #Not working to delegate via: delegate method, :to => Stalkerazzi::Tracker.instance
      %w(store_data track_event with_controller track_event_with_controller track_event_for_object).each do |method|
        class_eval <<-END_SRC, __FILE__, __LINE__
          def #{method}(*args)
            Stalkerazzi::Tracker.instance.#{method}(*args)
          end
        END_SRC
      end
    end
  end
end
