# lib/readyset-rails/configuration.rb

module Readyset
  class Configuration
    attr_accessor :connection_url

    def initialize
      @connection_url = ENV["READYSET_URL"]
    end
  end
end
