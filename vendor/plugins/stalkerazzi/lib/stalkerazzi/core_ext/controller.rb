ActionController::Base.class_eval do

  around_filter do |controller, action|
    Stalkerazzi::Tracker.instance.with_controller( controller ) { action.call }
    true
  end

  #cache_sweeper Stalkerazzi::Tracker
  extend Stalkerazzi::CoreExt::TrackingMethods

  def self.track_event_for( *args )
    meh_options = case args.last
      when Hash then args.pop
      when Proc then { :with => args.pop }
    end || {}

    filter_options = {
      :only => (args if args.any?{ |arg| arg.to_s != 'all'})
    }

    after_filter( filter_options ) do |controller|
      Stalkerazzi::Tracker.instance.track_event_with_controller( controller, meh_options )
      #controller.send( :track_event_for_controller, options )
    end
   #after_filter track_event_for_controller, filter_options (lambda {|controller|
   #
   # }, filter_options)
  end

  def track_event_for_controller( options = {} )
     Stalkerazzi::Tracker.with_controller( self ) do
       Stalkerazzi::Tracker.instance.track_event_for_object( self, options )
     end
  end

end
