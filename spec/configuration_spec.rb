# spec/configuration_spec.rb

require 'spec_helper'
require 'readyset/configuration'

RSpec.describe Readyset::Configuration do
  describe '#initialize' do
    it 'initializes shard with the symbol :readyset' do
      config = Readyset::Configuration.new
      expect(config.shard).to eq(:readyset)
    end

    it 'initializes migration_path to be db/readyset_caches.rb' do
      config = Readyset::Configuration.new

      expected = File.join(Rails.root, 'db/readyset_caches.rb')
      expect(config.migration_path).to eq(expected)
    end

    it 'initializes failover.enabled with false' do
      config = Readyset::Configuration.new
      expect(config.failover.enabled).to eq(false)
    end

    it 'initializes failover.healthcheck_interval to be 5 seconds' do
      config = Readyset::Configuration.new
      expect(config.failover.healthcheck_interval).to eq(5.seconds)
    end

    it 'initializes failover.error_window_period to be 1 minute' do
      config = Readyset::Configuration.new
      expect(config.failover.error_window_period).to eq(1.minute)
    end

    it 'initializes failover.error_window_size to be 10' do
      config = Readyset::Configuration.new
      expect(config.failover.error_window_size).to eq(10)
    end
  end
end
