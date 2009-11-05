module Stalkerazzi
  module ModelTracker
    def self.extended( base )
      def self.extended( base )
        base.extend( Stalkerazzi::CoreExt::TrackingMethods )
        base.delegate :store_tracked_event, :to => base
      end
    end

    def store_tracked_event( data, options = {} )
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
      def tracked_fields( field_map )
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
