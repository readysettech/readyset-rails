# lib/readyset.rb

require "readyset/configuration"
require "readyset/connection"
require "readyset/command"
require "readyset/default_resolver"

module Readyset
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.current_config
    configuration.inspect
  end
end
