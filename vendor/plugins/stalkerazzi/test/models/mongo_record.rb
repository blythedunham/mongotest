begin
  MongoRecord
rescue => e
end

if defined?( MongoRecord )
  module Stalkerazzi
    module Storage
      module MongoRecord
        class Session < ::MongoRecord::Base
        end

        class Param < ::MongoRecord::Base
        end

        class Blank < ::MongoRecord::Base
          acts_as_stalkerazzi_data_store
        end

        class Statistic < ::MongoRecord::Base
          collection_name :statistics
          fields :user_id, :event_type, :controller, :action, :path, :sessions, :params
          acts_as_stalkerazzi_data_store
        end

        class EmbeddedStatistic < ::MongoRecord::Base
          acts_as_stalkerazzi_data_store

          collection_name :embedded_statistics
          fields :user_id, :event_type, :controller, :action, :path
          has_many :sessions, :class_name => 'Stalkerazzi::Storage::MongoRecord::Session'
          has_many :params,   :class_name => 'Stalkerazzi::Storage::MongoRecord::Param'

        end

        class TrackedEvent < ::MongoRecord::Base


          collection_name :tracked_events
          fields :application_id, :event_type, :user_id, :request, :timestamp
          
          #index :event_type, :user_id
          acts_as_stalkerazzi_data_store(
            :application_id => lambda{ rand(50000) },
            :event_type => :action_name,
            :user_id => :current_user_id,
            :headers => :headers,
            :timestamp => :timestamp,
            :lang => :language
          )


        end
      end
    end
  end
end
