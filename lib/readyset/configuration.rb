# lib/readyset/configuration.rb
require 'active_record'
require 'yaml'
require 'erb'

module Readyset
  class Configuration
    attr_accessor :database_url, :shard

    def initialize
      @database_url = fetch_database_url
      @shard = :readyset
    end

    private

    def fetch_database_url
      url_from_config || url_from_env || log_connection_error
    end

    def url_from_config
      return unless defined?(Rails)

      begin
        config = load_database_config
        url = config[Rails.env]['readyset']
        url['url'] if url && url['url']
      rescue StandardError => e
        Rails.logger.error("Error loading database configuration: #{e.message}")
        nil
      end
    end

    def url_from_env
      ENV['READYSET_URL']
    end

    def load_database_config
      config_path = Rails.root.join('config', 'database.yml')
      YAML.load(ERB.new(File.read(config_path)).result) if File.exist?(config_path)
    rescue StandardError => e
      Rails.logger.error("Failed to load database configuration: #{e.message}")
      nil
    end

    def log_connection_error
      Rails.logger.error('Failed to set database URL: No valid configuration found in config/database.yml or ENV')
      nil
    end
  end
end
