# lib/readyset/configuration.rb
require 'active_record'

module Readyset
  class Configuration
    attr_accessor :migration_path, :shard

    def initialize
      @migration_path = File.join(Rails.root, 'db/readyset_caches.rb')
      @shard = :readyset
    end
  end
end
