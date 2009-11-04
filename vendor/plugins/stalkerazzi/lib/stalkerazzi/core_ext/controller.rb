ActionController::Base.class_eval do

  around_filter do |controller, action|
    Stalkerazzi::Tracker.instance.with_controller( controller ) { action.call }
    true
  end

  #cache_sweeper Stalkerazzi::Tracker
  extend Stalkerazzi::CoreExt::TrackingMethods

  def self.track_event_for( *args )
    options = case args.last
      when Hash then args.pop
      when Proc then { :data => args.pop }
    end || {}

    filter_options = {}
    filter_options[:only] = args if args.any?{|arg| arg.to_s != 'all' }

    after_filter( filter_options ) do |controller|
      Stalkerazzi::Tracker.instance.track_event_with_controller( controller, options )
      true
    end

  end


end
