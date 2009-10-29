module Stalkerazzi

  module DefaultTracking
    def self.extended( base )
       base.class_eval do
         class_inheritable_accessor :default_tracker
         self.default_tracker = 'Stalkerazzi::Trackers::Logger'

         delegate :track_event_for_tracker, :to => base
         alias_method :track_event, :track_event_for_tracker unless method_defined?( :track_event )

         class << self
           alias_method :record_tracked_event, :log_tracked_event unless method_defined?(:record_tracked_event)
         end
       end
    end

    # track the event for the specified tracker
    def track_event( data, tracker_class = nil )
      #recording_options = options.reverse_merge( stalkerazzi_options )
      tracker_class ||= default_tracker

      tracker = case( tracker_class )
        when Proc then return tracker_class.call( data )
        when Symbol then tracker_class.to_s.classify.constantize
        when String then tracker_class.constantize
        else tracker_class
      end

      tracker.record_tracked_event( data )
    end

    def track_event_for_tracker( data, tracker = nil )
      track_event( data, tracker )
    end

    def log_tracked_event( data )
      logger.debug( "Tracked data: #{data.inspect}") if self.respond_to?( logger )
    end
  end
end
