begin
  MongoMapper
rescue => e
end

if defined?( MongoMapper )
  module Stalkerazzi
    module Trackers
      module Mongo
        class Session
          include MongoMapper::EmbeddedDocument
        end

        class Param
          include MongoMapper::EmbeddedDocument
        end

        class Blank
          include MongoMapper::Document
        end

        class Statistic
          include MongoMapper::Document

          key :user_id, Integer
          key :event_type, String
          key :controller, String
          key :action, String
          key :path, String
          key :sessions, Array
          key :params, Array
        end

        class EmbeddedStatistic
          include MongoMapper::Document

          key :user_id, Integer
          key :event_type, String
          key :controller, String
          key :action, String
          key :path, String

          many :sessions, :class_name => 'Stalkerazzi::Trackers::Mongo::Session'
          many :params, :class_name   => 'Stalkerazzi::Trackers::Mongo::Param'

        end
      end
    end
  end
end
