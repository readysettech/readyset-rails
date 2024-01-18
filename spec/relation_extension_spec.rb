# spec/relation_extension_spec.rb

RSpec.describe Readyset::RelationExtension do
  describe '#create_readyset_cache!' do
    it 'creates a cache on ReadySet with the given "always" parameter' do
      cache = build_and_create_cache(:cached_query)

      caches = Readyset::Query::CachedQuery.all

      expect(caches).to eq([cache])
    end
  end

  describe '#readyset_explain' do
    it 'returns the expected explain information' do
      output = Cat.select('breed').where(name: 'Whiskers').readyset_explain

      expected_explain = build(:explain)
      expect(output).to eq(expected_explain)
    end
  end
end
