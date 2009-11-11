module Stalkerazzi
  module CoreExt

    module ControllerSupport
      def self.extended( base )
        base.class_eval do
          class_inheritable_array :stalkerazzi_tracked_events
          self.stalkerazzi_tracked_events = []

          include InstanceMethods
          extend Stalkerazzi::CoreExt::TrackingMethods
          alias_method_chain :process, :stalkerazzi unless method_defined?( :process_without_stalkerazzi )
        end
      end

      module InstanceMethods
        # Override process to setup the controller context
        # And track events
        def process_with_stalkerazzi( *arguments )
          Stalkerazzi::Tracker.instance.controller = self
          process_without_stalkerazzi( *arguments )
        ensure
          track_events_for_controller
          Stalkerazzi::Tracker.instance.controller = nil
        end

        protected
        # Track events for this controller
        def track_events_for_controller
          stalkerazzi_tracked_events.each do |tracker_options|
            Stalkerazzi::Tracker.track_event_with_controller(
              self, tracker_options.first
            ) if should_track_events_for_option?( tracker_options.last )
          end
        end

        # Return true if the event should be tracked for this controller
        def should_track_events_for_option?( options )#:nodoc:
          if !Stalkerazzi::Tracker.enabled?
            false
          elsif options[:skip] && options[:skip].include?( action_name )
            false
          elsif options[:only]
            options[:only].include?(action_name)
          elsif options[:except]
            !options[:except].include?(action_name)
          else
            true
          end
        end
      end

      # Track the event for the actions
      # track_event_for :show, :index, {:storage => 'my_store'}
      # track_event_for :all, :except => :meh
      #
      # Options supported by tracker such as <tt>:storage</tt>
      # <tt>:with</tt> are supported
      # === Additional Options
      # <tt>:only</tt> - only track these actions
      # <tt>:except</tt> - track everything except these actions
      def track_event_for( *args )
        options = case args.last
          when Hash then args.pop
          when Proc then { :with => args.pop }
        end || {}

        options.symbolize_keys!

        unless all_or_blank?( args )
          options[:only]||=[]
          options[:only].concat( args )
        end

        controller_options = %w(only except skip).inject({}) do |controller_options, key|
          value = options.delete( key )
          controller_options[key] = value if value
          controller_options
        end

        self.stalkerazzi_tracked_events << [options, controller_options]
      end

      # Skip a previously tracked event
      #
      #   skip_event_tracking_for :show
      #   skip_event_tracking_for
      def skip_event_tracking_for( *args )
        options = extract_options( args )

        if all_or_blank?( args )
          self.stalkerazzi_tracked_events = []

        else
          stalkerazzi_tracked_events.each do |tracker_options|
            tracker_options.last[:skip] ||= []
            tracker_options.last[:skip].concat( args )
          end
        end
      end

      # Return true if :all or 'all' is in the list or the list is blank
      def all_or_blank?( args )#:nodoc:
        args.blank? || args.any?{|a| a.to_s == 'all' }
      end

    end
  end
end

ActionController::Base.extend Stalkerazzi::CoreExt::ControllerSupport
