class TrackersController < ApplicationController
  tracker :data => :simple_stats

  track_event_for :mongomapper_statistic,
    :tracker_class => 'Stalkerazzi::Trackers::Mongo::Statistic'
  track_event_for :mongomapper_embedded_statistic,
    :tracker_class => 'Stalkerazzi::Trackers::Mongo::EmbeddedStatistic'
  track_event_for :mongomapper_blank,
    :tracker_class => 'Stalkerazzi::Trackers::Mongo::Blank'

  track_event_for :simple_log,   :tracker_class => 'Stalkerazzi::Trackers::Logger'
  track_event_for :gfs_logger,   :tracker_class => 'Stalkerazzi::Trackers::GfsLogger'
  track_event_for :local_logger, :tracker_class => 'Stalkerazzi::Trackers::LocalLogger'

  TRACKED_ACTIONS = %w(mongomapper_statistic mongomapper_blank
    mongomapper_embedded_statistic simple_log
    gfs_logger local_logger) unless defined?( TRACKED_ACTIONS )

  TRACKED_ACTIONS.each do |method|
    define_method( method ) do
      render :text => 'ok'
    end
  end

  def mongo_filterless
    collection = MongoMapper.connection.db(MongoMapper.database.name).collection('standalone')
    collection.insert( simple_stats )

    render :text => 'ok'
  end

  def mongomapper_filterless
    Stalkerazzi::Trackers::Mongo::Statistic.create!( simple_stats )
    render :text => 'ok'
  end

  protected

  def simple_stats( options = {} )
    {
      :params => [params],
      :event_type => "super_#{rand(6666666)}",
      :user_id => rand(400),
      :path => request.path,
      :action => "#{params[:action]}_#{rand(50)}"
    }
  end
end

