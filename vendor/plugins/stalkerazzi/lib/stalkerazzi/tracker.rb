module Stalkerazzi
  module Tracking
    def self.included( base )
      base.class_eval do
        class_inheritable_accessor :logger
        self.logger = nil

        class_inheritable_hash :stalkerazzi_options
        self.stalkerazzi_options = {
          :logger => (ActiveRecord::Base.logger if Rails.env != 'production'),
          :storage => 'Stalkerazzi::Trackers::Logger'
        }

        class_inheritable_accessor :tracker_fields
        self.tracker_fields = {
          :controller => :tracked_controller,
          :action     => :tracked_action,
          :path       => :tracked_path,
          :headers    => :tracked_headers,
          :session    => :tracked_session,
          :timestamp  => :tracked_timestamp,
          :params     => :tracked_params,
          :remote_ip  => :remote_ip,
          :referrer   => :referer,
          :user_id    => :tracked_user
        }
        extend( ClassMethods )
      end
    end

    module ClassMethods
      def configure( options={} )
        options.symbolize_keys!

        track_fields( options.delete( :fields ) )

        self.logger = options.delete( :logger ) if options.has_key?( :logger )

        self.stalkerazzi_options.update( options )
      end

      def track_field( field_name, value)
        track_fields( field_name => value )
      end

      def track_fields( field_map = {} )
        unless field_map.blank?
          stalkerazzi_options[:fields]||={}
          stalkerazzi_options[:fields].update( field_map.symbolize_keys )
        end
      end
    end


    # Tracker classes should implement :perform_tracking and :store_data
    def store_data( data, options ={} )
      log_stored_event( data )
      invoke_method_for_class( :storage, :store_tracked_event, options, data, ActiveRecord::Base )
    end

    def log_stored_event( data )
      puts "Tracked data: #{data.inspect}" if Rails.env == 'development'
      logger.debug( "Tracked data: #{data.inspect}") if logger
    end

    # Track events by saving
    #
    # ===Options
    # <tt>:data</tt> - (Optional) A hash or a proc that returns a hash of the
    #    raw  data. When not specified, +tracked_event_data+ is invoked to format
    #    the data
    # <tt>:tracker</tt> - The class name of the ActiveRecord, Document, or other object
    #    used to record the data. Defaults +Statistic+
    # <tt>:fields</tt> - Additional field mappings
    # <tt>:default_data</tt> - Default the fields specified here
    # <tt>:only</tt>
    def perform_tracking( tracker_options ={} )
      options = tracker_options.reverse_merge( stalkerazzi_options )
      data = options.delete( :data )
      statistic_data = case data
         when Hash then data
         when Proc then options.call( self, options )
         when String, Symbol then controller.send( data, options ) if controller
         else tracked_event_data( options )
      end
      store_data( statistic_data, options )
    end

    # return the class or object
    def class_for_setting( key, options = {}, method_options = {}, default_class = nil )
      class_for_value(
        tracker_setting( key, options ),
        method_options || options ,
        default_class
      )
    end

    # Look for the setting first in the options hash, then in the default values
    def tracker_setting( key, options ={} )
      options[ key ] || stalkerazzi_options[ key ]
    end

    # Return the class represented by the symbol, class or string
    # If klass is a proc, then it is invoked with the method options
    def class_for_value( klass, options ={}, default_class = nil)
      case klass
        when NilClass then default_class
        when Proc then klass.call( method_options || options ) and return nil
        when Symbol then klass.to_s.classify.constantize
        when String then klass.constantize
        else klass
      end
    end

    def invoke_method_for_class( key, method, options = {}, method_options ={}, default_class = nil)
      klass = class_for_setting( key, options, method_options, default_class )
      puts "INVOKE: b=#{klass.inspect} m=#{method.inspect} k=#{key}"
      klass.try( method, method_options || options )
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
    def tracked_event_data( options = {} )
      puts options.inspect
      tracked_statistics = (stalkerazzi_options[:fields]||{}).merge( options[:fields] || {} )

      key_names = tracked_statistics.keys

      if options[:only]
        options.delete(:except)
        key_names = key_names & Array(options[:only]).collect { |n| n.to_s }
      else
        options[:except] = Array(options[:except])
        key_names = key_names - options[:except].collect { |n| n.to_s }
      end

      key_names.inject( options[:default_data] || {} ) do |data, name|
        data[ name.to_sym ] = tracked_event_field_data( name ) unless data.has_key?( name )
        data
      end
    end

    def tracked_event_field_data( name, tracked_statistics = nil )
      tracked_statistics ||= stalkerazzi_options[:fields]

      if tracked_statistics.has_key?( name.to_sym )
        tracked_method = tracked_statistics[ name.to_sym ] || name

        if tracked_method.is_a?( Proc )
          tracked_method.call( self )

        elsif respond_to?( tracked_method )
          send( tracked_method ).to_s

        elsif request.respond_to?( tracked_method )
          request.send( tracked_method ).to_s

        else
          name
        end
      else
        nil
      end
    end
  end

  module TrackingMethodHelper
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

    def with_controller( controller, save_thread = false, &block )
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
    include TrackingMethodHelper

    def track_event( options = {} )
      invoke_method_for_class( :tracker, :perform_tracking, options, nil, Stalkerazzi::Tracker )
    end

    def track_event_with_controller( controller, options = {} )
      with_controller( controller ) { track_event( options) }
    end

    public
    class << self
      #Not working to delegate via: delegate method, :to => Stalkerazzi::Tracker.instance
      %w(store_data perform_tracking track_event track_event_with_controller).each do |method|
        class_eval <<-END_SRC, __FILE__, __LINE__
          def #{method}(*args)
            Stalkerazzi::Tracker.instance.#{method}(*args)
          end
        END_SRC
      end
    end
  end
end
