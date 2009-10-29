module Stalkerazzi
  module ModelTracker
    def self.extended( base )
      base.extend ::Stalkerazzi::DefaultTracking
    end



    def record_tracked_event( data )
      create( data )
    end
  end
end

ActiveRecord::Base.extend        Stalkerazzi::ModelTracker


#puts "AR"
#MongoMapper::Document::ClassMethods.send :include, Stalkerazzi::ModelTracker
#MongoMapper::Document::ClassMethods.send :include, Stalkerazzi::DefaultTracking
MongoMapper::Document.module_eval do
  def self.included_with_stalkerazzi( base )
    included_without_stalkerazzi( base )
    base.extend Stalkerazzi::ModelTracker
  end

  class << self
    alias_method_chain :included, :stalkerazzi unless method_defined?(:included_without_stalkerazzi)
  end
end
