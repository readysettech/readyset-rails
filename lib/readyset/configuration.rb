# lib/readyset/configuration.rb
require 'active_record'

module Readyset
  class Configuration
    attr_accessor :database_url, :shard

    def initialize
      @database_url = ENV['READYSET_URL'] || default_connection_url
      @shard = :readyset
    end

    def default_connection_url
      # Check if Rails is defined and if database configuration is available
      'postgres://user:password@localhost:5432/readyset'
    end
  end
end
