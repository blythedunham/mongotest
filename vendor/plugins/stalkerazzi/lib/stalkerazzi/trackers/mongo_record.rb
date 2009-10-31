begin
  MongoRecord
rescue => e
end

if defined?( MongoRecord )
  module Stalkerazzi
    module Trackers
      module MongoRecord
        class Session < ::MongoRecord::Base
        end

        class Param < ::MongoRecord::Base
        end

        class Blank < ::MongoRecord::Base
        end

        class Statistic < ::MongoRecord::Base
          collection_name :statistics
          fields :user_id, :event_type, :controller, :action, :path, :sessions, :params
        end

        class EmbeddedStatistic < ::MongoRecord::Base
          collection_name :embedded_statistics
          fields :user_id, :event_type, :controller, :action, :path
          has_many :sessions, :class_name => 'Stalkerazzi::Trackers::MongoRecord::Session'
          has_many :params,   :class_name => 'Stalkerazzi::Trackers::MongoRecord::Param'

        end
      end
    end
  end
end