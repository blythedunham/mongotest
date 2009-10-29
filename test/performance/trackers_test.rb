require File.dirname(__FILE__) + '/../test_helper'
require 'performance_test_help'

class MongoTest < ActionController::PerformanceTest
  def test_mongo_connection
    db = Mongo::Connection.new('localhost').db('sample-db')
  end

  PERF_ACTIONS = TrackersController::TRACKED_ACTIONS +
    %w( mongo_filterless mongomapper_filterless ) unless defined?( PERF_ACTIONS )

  PERF_ACTIONS.each do |action|
    define_method("test_#{action}") do
      get "/trackers/#{action}?test_param=#{rand(1000)}"
    end
  end

end
