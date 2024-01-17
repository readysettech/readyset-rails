RSpec.describe Readyset::Caches do
  describe '.cache' do
    after(:each) do
      Readyset::Caches.instance_variable_set(:@caches, nil)
    end

    it 'adds a cache with the given attributes to the @caches ivar' do
      query = build(:cached_query, always: true, count: nil, name: nil)

      Readyset::Caches.cache(always: true, id: query.id) { query.text }

      caches = Readyset::Caches.instance_variable_get(:@caches)
      expect(caches.size).to eq(1)
      expect(caches.first).to eq(query)
    end

    context 'when no always parameter is passed' do
      it 'defaults the always parameter to false' do
        query = build(:cached_query, count: nil, name: nil)

        Readyset::Caches.cache(id: query.id) { query.text }

        always = Readyset::Caches.instance_variable_get(:@caches).first.always
        expect(always).to eq(false)
      end
    end
  end

  describe '.caches' do
    it 'returns the caches stored in the @caches ivar' do
      query = build(:cached_query, count: nil, name: nil)
      Readyset::Caches.cache(always: query.always, id: query.id) { query.text }

      result = Readyset::Caches.caches

      expect(result.size).to eq(1)
      expect(result.first).to eq(query)
    end
  end
end
