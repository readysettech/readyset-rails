# lib/readyset/configuration.rb
require 'active_record'

module Readyset
  class Configuration
    attr_accessor :migration_path, :shard

    def initialize
      @migration_path = File.join(Rails.root, 'db/readyset_caches.rb')
      @shard = :readyset
    end

    def failover
      if @failover
        @failover
      else
        inner = ActiveSupport::OrderedOptions.new
        inner.enabled = false
        inner.healthcheck_interval = 5.seconds
        inner.error_window_period = 1.minute
        inner.error_window_size = 10
        @failover = inner
      end
    end

    def hostname
      ActiveRecord::Base.configurations.configs_for(name: shard.to_s).configuration_hash[:host]
    end
  end
end
