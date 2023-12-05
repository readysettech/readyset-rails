# configuration_spec.rb
# spec/readyset-rails/configuration_spec.rb

require 'spec_helper'
require 'readyset/configuration'

RSpec.describe Readyset::Configuration do
  let(:config) { described_class.new }

  context 'when no database_url is specified' do
    it 'defaults to dummy url' do
      default_url = 'postgres://user:password@localhost:5432/readyset'
      expect(config.database_url).to eq default_url
    end
  end

  context 'when database_url ENV var is specified' do
    it 'is used instead of dummy url' do
      ENV['READYSET_URL'] = 'postgres://test:password@localhost:5433/readyset'
      expect(config.database_url).to eq 'postgres://test:password@localhost:5433/readyset'
    end
  end

  context 'when database_url is specified' do
    it 'is used instead of dummy url' do
      readyset_url = 'postgres://user_test:password@localhost:5433/readyset'
      config.database_url = readyset_url

      expect(config.database_url).to eq readyset_url
    end
  end
end
