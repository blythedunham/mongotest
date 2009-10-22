module Mongolytics
  class Statistic
    include MongoMapper::Document

    key :controller, String, :required => true
    key :action, String, :required => true
    key :path, String

    many :sessions, :class_name => 'Mongolytics::Session'
    many :params, :class_name => 'Mongolytics::Param'

    def self.stats_for_path(path)
      count({:path => path})
    end

    def self.stats_for_keys(controller, action)
      count({:controller => controller.to_s, :action => action.to_s})
    end
  end
end
