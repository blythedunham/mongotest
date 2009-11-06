class User < ActiveRecord::Base
  auto_track_event(
    :with => lambda { |record|
      {
        :user_id => record.id,
        :event_type => 'USER SAVE'
      }
    }
  )

end
