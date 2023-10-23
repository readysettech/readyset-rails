# lib/readyset-rails/configuration.rb

module Readyset
  class Configuration
    attr_accessor :connection_url

    def initialize
      @connection_url = ENV["READYSET_URL"] || default_connection_url
    end

    def default_connection_url
      # Logic to pull the connection URL from database.yml goes here.
      # For simplicity, I'll just return a dummy URL. In a real-world scenario,
      # you'd parse the YAML file and fetch the 'primary_replica' details.
      "postgres://user:password@localhost:5432/readyset"
    end
  end
end
