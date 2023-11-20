# lib/ready_set.rb

require 'ready_set/configuration'
require 'ready_set/connection'
require 'ready_set/command'
require 'ready_set/default_resolver'
require 'ready_set/middleware'
require "ready_set/controller_extension"

require_relative './ready_set/railtie' if defined?(Rails::Railtie)

module ReadySet
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
