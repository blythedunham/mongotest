class TrackersController < ApplicationController

  track_event_for :mongomapper_statistic,
    :tracker_class => 'Stalkerazzi::Storage::Mongo::Statistic',
    :data => :simple_stats

  track_event_for :mongomapper_embedded_statistic,
    :tracker_class => 'Stalkerazzi::Storage::Mongo::EmbeddedStatistic',
    :data => :simple_stats

  track_event_for :mongomapper_blank,
    :tracker_class => 'Stalkerazzi::Storage::Mongo::Blank',
    :data => :simple_stats

  track_event_for :simple_log,   :tracker_class => 'Stalkerazzi::Storage::Logger',
    :data => :simple_stats
  track_event_for :gfs_logger,   :tracker_class => 'Stalkerazzi::Storage::GfsLogger',
    :data => :simple_stats
  track_event_for :local_logger, :tracker_class => 'Stalkerazzi::Storage::LocalLogger',
    :data => :simple_stats

  TRACKED_ACTIONS = %w(mongomapper_statistic mongomapper_blank
    mongomapper_embedded_statistic simple_log
    gfs_logger local_logger) unless defined?( TRACKED_ACTIONS )

  TRACKED_ACTIONS.each do |method|

    define_method( method ) do
      render :text => action_name
    end
  end

  def mongo_filterless
    collection = MongoMapper.connection.db(MongoMapper.database.name).collection('standalone')
    collection.insert( simple_stats )

    render :text => 'ok'
  end

  def blah
    track_event(:event_type => 'asdasdf')
    render :text => 'blah'
  end

  def ar_test
    User.create(:uuid => rand(3453434534535), :username => 'asdfasdf' + rand(10000).to_s )
    render :text => 'ok'
  end

  def mongomapper_filterless
    Stalkerazzi::Storage::Mongo::Statistic.create!( simple_stats )
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

