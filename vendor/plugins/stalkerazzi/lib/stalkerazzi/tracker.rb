module Stalkerazzi
  class Tracker
    include Singleton
    include ::Stalkerazzi::Tracking
    include ::Stalkerazzi::RequestContext

    public
    class << self
      #Not working to delegate via: delegate method, :to => Stalkerazzi::Tracker.instance
      %w(store_data track_event with_controller track_event_with_controller 
         track_event_for_object enabled?).each do |method|
        class_eval <<-END_SRC, __FILE__, __LINE__
          def #{method}(*args)
            Stalkerazzi::Tracker.instance.#{method}(*args)
          end
        END_SRC
      end
    end
  end
end
