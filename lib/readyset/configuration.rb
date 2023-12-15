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
    rescue StandardError => e
      Rails.logger.error("Error loading database configuration: #{e.message}")
      nil
    end

    def url_from_config
      return unless defined?(Rails)

      config = load_database_config
      url = config[Rails.env]['readyset']
      if url && url['url']
        url['url']
      end
    end

    def url_from_env
      ENV['READYSET_URL']
    end

    def load_database_config
      config_path = Rails.root.join('config', 'database.yml')
      YAML.safe_load(ERB.new(File.read(config_path)).result) if File.exist?(config_path)
    end
  end
end
