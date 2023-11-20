# default_resolver_spec.rb

require 'spec_helper'
require_relative './../lib/ready_set/default_resolver'

RSpec.describe ReadySet::DefaultResolver do
  describe '#read_from_replica?' do
    let(:resolver) { ReadySet::DefaultResolver.new({ delay: 2.seconds }) }

    it 'returns true by default' do
      expect(resolver.read_from_replica?(nil)).to be true
    end
  end
end
