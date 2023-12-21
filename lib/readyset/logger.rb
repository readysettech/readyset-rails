# lib/ready_set/logger.rb

module Readyset
  module Logger
    VALID_LOG_LEVELS = %i(debug info warn error fatal unknown).freeze

    def self.log(level, message)
      raise ArgumentError, "Invalid log level: #{level}" unless valid_log_level?(level)

      @logger ||= initialize_logger
      @logger.public_send(level, formatted_message(level, message))
    end

    def self.valid_log_level?(level)
      VALID_LOG_LEVELS.include?(level)
    end

    def self.initialize_logger
      logger = ::Logger.new(STDOUT)
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime}: #{severity} - #{msg}\n"
      end
      logger
    end

    def self.formatted_message(level, message)
      "[Readyset][#{level.upcase}] #{message}"
    end
  end
end
