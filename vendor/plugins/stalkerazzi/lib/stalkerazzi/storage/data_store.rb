module Stalkerazzi
  module Storage
    module DataStore
      def self.included( base )
        base.class_inheritable_hash :tracked_fields unless base.respond_to?( :tracked_fields )
        base.extend( TrackFieldMethods )
        base.extend( StoreTrackedEvent ) unless base.respond_to?( :store_tracked_event )
        base.delegate :store_tracked_event, :to => base
      end

      module TrackFieldMethods
        def track_fields( fields = {} )
          self.tracked_fields ||= {}
          self.tracked_fields.update( fields.symbolize_keys )
        end
        def track_field( name, value )
          self.tracked_fields[ name.to_sym ] = value
        end
      end

      module StoreTrackedEvent
         def store_tracked_event( data, options = {} )
          raise "Overwrite store_tracked_event"
        end
      end
    end
  end
end
