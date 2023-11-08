# configuration_spec.rb
# spec/readyset-rails/configuration_spec.rb

require 'spec_helper'
require_relative './../lib/ready_set/configuration.rb'

RSpec.describe ReadySet::Configuration do
  let(:config) { described_class.new }

  describe '#initialize' do
    it 'sets default values' do
      config = ReadySet::Configuration.new

      expect(config.connection_url).
        to eq(ENV['READYSET_URL'] || 'postgres://user:password@localhost:5432/readyset')
      expect(config.database_selector).to eq({ delay: 2.seconds })
      expect(config.database_resolver).to eq(ReadySet::DefaultResolver)
      expect(config.database_resolver_context).to be_nil
    end
  end

  describe '#connection_url' do
    context 'when READYSET_URL is set' do
      before { ENV['READYSET_URL'] = 'custom_url' }
      after { ENV.delete('READYSET_URL') }

      it 'returns the value from the environment variable' do
        expect(config.connection_url).to eq('custom_url')
      end
    end

    context 'when READYSET_URL is not set' do
      it 'returns the default connection URL' do
        expect(config.connection_url).to eq('postgres://user:password@localhost:5432/readyset')
      end
    end
  end
end
