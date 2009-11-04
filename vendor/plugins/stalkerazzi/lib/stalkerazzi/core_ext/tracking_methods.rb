module Stalkerazzi
  module CoreExt
    module TrackingMethods
      def self.extended( base )
        def self.extended( base )
          class << base
            #alias_method :record_tracked_event, :create
            delegate :track_event, :to => Stalkerazzi::Tracker
            delegate :track_fields, :to => Stalkerazzi::Tracker
            delegate :track_field, :to => Stalkerazzi::Tracker
          end
          base.delegate :track_event, :to => Stalkerazzi::Tracker
        end
      end
    end
  end
end