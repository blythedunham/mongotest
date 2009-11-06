module Stalkerazzi
  module ModelTracker
    def self.extended( base )
      def self.extended( base )
        base.extend( Stalkerazzi::CoreExt::TrackingMethods )
      end
    end

    # Automatically track an event with callbacks
    # === Options
    # In addition to the +track_events+, the following can be specified
    # * <tt>:with</tt> A hash or proc that returns a hash with the data to store.
    #   The hash is merged with the default field values ( example request headers )
    # * <tt>:callback</tt> Callback to use. Defaults to :after_save
    # * <tt>:storage</tt> The
    # === Examples
    #  Track the defaults setup by the storage class
    #    auto_track_event
    #    > {:current_user_name => 'admin', :controller => 'users', :action => 'show' }
    #   
    #  Set the user name to the record's user_name and save the event as 'Save User'
    #    auto_track_event :with => lambda { |record| {:user_name => record.user_name, :event_type => 'Save User'} }
    #    > {:current_user_name => 'new_user', :event_type => 'Save User', :controller => 'users', :action => 'show' }
    def auto_track_event( options = {})
      options.symbolize_keys!
      callback = options.delete( :callback ) || :after_save
      callback_options = { :if => options.delete( :if ) }

      tracker_proc = lambda{ |record|
        Stalkerazzi::Tracker.track_event_for_object( record, options )
      }

      send( callback, tracker_proc, callback_options )
    end

    # Acts as a storage class
    def acts_as_stalkerazzi_data_store( fields = {} )
      include( Stalkerazzi::Storage::DataStore )
      track_fields( fields )
    end

    def store_tracked_event( data, options = {} )
      puts "CREATE DATA: #{data.inspect}"
      create( data )
    end
  end
end

if defined?( ActiveRecord ) and defined?( ActiveRecord::Base )
  ActiveRecord::Base.extend        Stalkerazzi::ModelTracker
end

if defined?( MongoRecord ) and defined?( MongoRecord::Base)
  MongoRecord::Base.class_eval do
    extend Stalkerazzi::ModelTracker 
    class << self
      def fields_with_trackers( field_map )
        track_fields( field_map )
        fields( *field_map.keys )
      end
    end
  end
end

if defined?( MongoMapper ) and defined?( MongoMapper::Document )
  #MongoMapper::Document::ClassMethods.send :include, Stalkerazzi::ModelTracker
  #MongoMapper::Document::ClassMethods.send :include, Stalkerazzi::DefaultTracking
  MongoMapper::Document.module_eval do
    def self.included_with_stalkerazzi( base )
      included_without_stalkerazzi( base )
      base.extend Stalkerazzi::ModelTracker
    end

    class << self
      alias_method_chain :included, :stalkerazzi unless method_defined?(:included_without_stalkerazzi)
    end
  end
end
