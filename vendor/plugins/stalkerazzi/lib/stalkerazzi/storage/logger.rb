module Stalkerazzi
  module Trackers
    class Logger

      class_inheritable_accessor :logger
      self.logger = Rails.logger

      def self.store_tracked_event( data, options = {} )
        logger.debug "RECORD TRACKER STAT: #{ data.inspect }"
      end

      def self.create_logger( file_name )
        b_logger = ActiveSupport::BufferedLogger.new(file_name)
        b_logger.level = ActiveSupport::BufferedLogger.const_get(Rails.configuration.log_level.to_s.upcase)
        if Rails.env == "production"
          b_logger.auto_flushing = false
        end
        b_logger
      end
    end

    class GfsLogger < Logger
      self.logger = self.create_logger( File.join( Rails.root, 'gfslogger_' + Time.now.to_s(:db)))
    end

    class LocalLogger < Logger
      self.logger = self.create_logger( File.join( Rails.root, 'locallogger_' + Time.now.to_s(:db)))
    end
  end
end


