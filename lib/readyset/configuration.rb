# lib/readyset/configuration.rb
require 'active_record'

module Readyset
  class Configuration
    attr_accessor :enable_failover, :failover_error_window_period, :failover_error_window_size,
      :failover_healthcheck_interval, :migration_path, :shard

    def initialize
      @enable_failover = false
      @failover_healthcheck_interval = 5.seconds
      @failover_error_window_period = 1.minute
      @failover_error_window_size = 10
      @migration_path = File.join(Rails.root, 'db/readyset_caches.rb')
      @shard = :readyset
    end

    def hostname
      ActiveRecord::Base.configurations.configs_for(name: shard.to_s).configuration_hash[:host]
    end
  end
end
