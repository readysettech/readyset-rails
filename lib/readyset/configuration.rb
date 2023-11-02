# lib/readyset/configuration.rb

module Readyset
  class Configuration
    attr_accessor :connection_url, :database_selector, :database_resolver,
      :database_resolver_context

    def initialize
      @connection_url = ENV['READYSET_URL'] || default_connection_url
      @database_selector = { delay: 2.seconds }
      @database_resolver = Readyset::DefaultResolver
      @database_resolver_context = nil
    end

    def default_connection_url
      # Check if Rails is defined and if database configuration is available
      if defined?(Rails) && Rails.application && Rails.application.config.database_configuration
        # Fetch the environment-specific configuration
        config = Rails.application.config.database_configuration[Rails.env]

        # Fetch the 'primary_replica' details if available, otherwise fallback to default database
        replica_config = config['primary_replica'] || config

        # Construct the URL based on the configuration
        adapter = replica_config['adapter']
        user = replica_config['username']
        password = replica_config['password']
        host = replica_config['host']
        port = replica_config['port']
        db = replica_config['database']

        "#{adapter}://#{user}:#{password}@#{host}:#{port}/#{db}"
      else
        # Fallback dummy URL
        'postgres://user:password@localhost:5432/readyset'
      end
    end
  end
end
