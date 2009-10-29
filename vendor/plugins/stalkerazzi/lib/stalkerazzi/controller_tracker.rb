module Stalkerazzi
  module ControllerTracker
    def self.included( base )
      base.class_inheritable_accessor :tracker_fields
      base.tracker_fields = {
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

      base.class_inheritable_accessor :tracker_data
      base.tracker_data = :tracked_event_data

      base.extend( ClassMethods )
      base.extend( Stalkerazzi::DefaultTracking )
    end

    module ClassMethods

      def tracker( options )
        self.tracker_data =    options[:data]          if options.has_key?( :data )
        self.tracker_fields =  options[:fields]        if options.has_key?( :fields )
        self.default_tracker = options[:tracker_class] if options.has_key?( :tracker_class )
      end

      def track_event_for( *args )

        options = case args.last
          when Hash then args.pop
          when Proc then { :data => args.pop }
          else {}
        end

        filter_options = {}
        filter_options[:only] = args if args.any?{|arg| arg.to_s != 'all' }

        after_filter( 
          lambda{ |controller| controller.track_event( options ) }, filter_options
        )
  
      end
    end


    # Track events by saving
    #
    # ===Options
    # <tt>:data</tt> - (Optional) A hash or a proc that returns a hash of the
    #    raw  data. When not specified, +tracked_event_data+ is invoked to format
    #    the data
    # <tt>:tracker_class</tt> - The class name of the ActiveRecord, Document, or other object
    #    used to record the data. Defaults +Statistic+
    # <tt>:tracked_statistics</tt> - Options used by +tracked_event_data+ to generate the recorded data
    def track_event( options ={} )
      data = options.delete( :data ) || tracker_data
      statistic_data = case data
         when Proc then options.call( self, options[:track] )
         when String, Symbol then self.send( data, options )
         when Hash then data
         else tracked_event_data( options[:track] )
      end

      track_event_for_tracker( statistic_data, options[:tracker_class] )
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
    # * <tt>:defaults </tt> - a hash of defaulted data
    # * <tt>:fields</tt> - additional tracked statistics
    def tracked_event_data( options = {} )
      tracked_statistics = self.tracker_fields.merge( options[:fields] || {} )
      key_names = tracked_statistics.keys

      if options[:only]
        options.delete(:except)
        key_names = key_names & Array(options[:only]).collect { |n| n.to_s }
      else
        options[:except] = Array(options[:except])
        key_names = key_names - options[:except].collect { |n| n.to_s }
      end

      key_names.inject( options[:defaults] || {} ) do |data, name|
        data[ name.to_sym ] = tracked_event_field_data( name ) unless data.has_key?( name )
        data
      end
    end

    def tracked_event_field_data( name, tracked_statistics = nil )
      tracked_statistics ||= self.tracker_fields

      if tracked_statistics.has_key?( name.to_sym )
        tracked_method = tracked_statistics[ name.to_sym ] || name

        if tracked_method.is_a?( Proc )
          tracked_method.call( self )

        elsif self.responds_to?( tracked_method )
          send( tracked_method ).to_s

        elsif request.responds_to?( tracked_method )
          request.send( tracked_method ).to_s

        else
          name
        end
      else
        nil
      end
    end

    #predefined methods
    def tracked_headers
      request.headers.reject { |k,v| !v.is_a?( String ) }
    end
    def tracked_session;      [session]; end
    def tracked_params;       [params]; end
    def tracked_controller;   params[:controller].to_s; end
    def tracked_action;       params[:action].to_s; end
    def tracked_timestamp;    Time.now; end
    def tracked_user;         current_user.to_param; end
  end
end

ActionController::Base.send :include, Stalkerazzi::ControllerTracker
