module Stalkerazzi
  module Storage
    class Logger
      include Stalkerazzi::Storage::DataStore

      def self.store_tracked_event( data, options = {} )
        self.logger ||= self.create_logger( File.join( Rails.root, 'log', 'stalkerazzi.log') )
        logger.info data.inspect
      end

      def self.create_logger( file_name )
        b_logger = ActiveSupport::BufferedLogger.new( file_name )
        b_logger.level = ActiveSupport::BufferedLogger.const_get(Rails.configuration.log_level.to_s.upcase)
        if Rails.env == "production"
          b_logger.auto_flushing = false
        end
        b_logger
      end
      class_inheritable_accessor :logger
    end
  end
end


