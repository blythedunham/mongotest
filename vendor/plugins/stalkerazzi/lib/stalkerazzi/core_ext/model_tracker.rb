module Stalkerazzi
  module ModelTrackerOld
    def self.extended( base )
      base.extend ::Stalkerazzi::DefaultTracking
    end

    def record_tracked_event( data )
      create( data )
    end
  end
end



module Stalkerazzi
  module ModelTracker
    def self.extended( base )
      def self.extended( base )
        base.extend( Stalkerazzi::CoreExt::TrackingMethods )
        #class << base
          #alias_method :record_tracked_event, :create
        #  delegate :track_event, :to => Stalkerazzi::Tracker
        #end
        #base.delegate :track_event, :to => Stalkerazzi::Tracker
        base.delegate :record_tracked_event, :to => base
      end
    end

    def store_tracked_event( data, options )
      create( data )
    end
  end
end

ActiveRecord::Base.extend        Stalkerazzi::ModelTracker

puts "DEFINED MODEL"
if defined?( MongoRecord ) and defined?( MongoRecord::Base)
  puts "MONGO RECORD"
  MongoRecord::Base.class_eval do
    extend Stalkerazzi::ModelTracker 
    class << self
      def tracked_fields( field_map )
        track_fields( field_map )
        fields( *field_map.keys )
      end
    end
  end
end

if defined?( MongoMapper )
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