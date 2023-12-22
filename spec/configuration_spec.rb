# spec/configuration_spec.rb

require 'spec_helper'
require 'readyset/configuration'

RSpec.describe Readyset::Configuration do
  describe '#initialize' do
    it 'initializes shard with the symbol :readyset' do
      config = Readyset::Configuration.new
      expect(config.shard).to eq(:readyset)
    end
  end
end
