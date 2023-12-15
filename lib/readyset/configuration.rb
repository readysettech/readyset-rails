# lib/readyset/configuration.rb
require 'active_record'

module Readyset
  class Configuration
    attr_accessor :shard

    def initialize
      @shard = :readyset
    end
  end
end
