# lib/readyset.rb

require "readyset/configuration"
require "readyset/connection"
require "readyset/command"

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
end
