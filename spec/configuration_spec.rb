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
  end
end
