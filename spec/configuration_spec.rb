# configuration_spec.rb
# spec/readyset-rails/configuration_spec.rb

require 'spec_helper'
require_relative './../lib/ready_set/configuration.rb'

RSpec.describe ReadySet::Configuration do
  let(:config) { described_class.new }
  # Combustion-dependent url string
  let(:default_url) { 'sqlite3://:@:/db/combustion_test.sqlite' }

  around do |example|
    original_env = ENV.to_hash
    example.run
    ENV.replace(original_env)
  end

  describe '#initialize' do
    # NOTE: This is providing excessive coverage,
    # this may be changed later on as we improve config.
    it 'sets default values' do
      expect(config.connection_url).to eq(ENV['READYSET_URL'] || default_url)
      expect(config.database_selector).to eq({ delay: 2.seconds })
      expect(config.database_resolver).to eq(ReadySet::DefaultResolver)
      expect(config.database_resolver_context).to be_nil
    end
  end

  describe '#connection_url' do
    context 'when READYSET_URL is set' do
      it 'returns the value from the environment variable' do
        ENV['READYSET_URL'] = 'custom_url'
        expect(config.connection_url).to eq('custom_url')
      end
    end

    # NOTE: Passes, but misleading as this behavior
    # isn't defaulting within the config class.
    # Placeholder for later once the config is tackled.
    xcontext 'when READYSET_URL is not set' do
      it 'returns the default connection URL' do
        ENV['READYSET_URL'] = nil
        expect(config.connection_url).to eq(default_url)
      end
    end
  end
end
