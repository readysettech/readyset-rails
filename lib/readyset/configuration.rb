# lib/readyset/configuration.rb

module Readyset
  class Configuration
    attr_accessor :database_url

    def initialize
      @database_url = ENV['READYSET_URL'] || default_connection_url
    end

    def self.current_config
      configuration.inspect
    end

    def default_connection_url
      # Check if Rails is defined and if database configuration is available
      'postgres://user:password@localhost:5432/readyset'
    end

    # @return [Readyset::Configuration] Readyset's current configuration
    def self.configuration
      @configuration ||= Configuration.new
    end

    # Set Readyset's configuration
    # @param config [Readyset::Configuration]
    class << self
      attr_writer :configuration
    end

    # Modify Readyset's current configuration
    # @yieldparam [Readyset::Configuration] config current Readyset config
    def self.configure
      yield configuration
    end
  end
end
