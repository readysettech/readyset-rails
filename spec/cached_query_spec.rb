# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Readyset::Query::CachedQuery do
  describe '.all' do
    subject { Readyset::Query::CachedQuery.all }

    it_behaves_like 'a wrapper around a ReadySet SQL extension', 'SHOW CACHES' do
      let(:query) { build(:cached_query) }
      let(:raw_query_result) do
        [
          {
            'query id' => query.id,
            'query text' => query.text,
            'fallback behavior' => 'fallback allowed',
            'cache name' => query.name,
            'count' => query.count.to_s,
          },
        ]
      end
      let(:expected_output) { [query] }
    end
  end

  describe '.drop_all!' do
    subject { Readyset::Query::CachedQuery.drop_all! }

    it_behaves_like 'a wrapper around a ReadySet SQL extension', 'DROP ALL CACHES'
  end

  describe '.find' do
    subject { Readyset::Query::CachedQuery.find(query_id) }

    context 'when a cached query with the given ID exists' do
      let(:query) { build(:cached_query) }
      let(:query_id) { query.id }

      it_behaves_like 'a wrapper around a ReadySet SQL extension',
          'SHOW CACHES WHERE query_id = ?' do
        let(:args) { query_id }
        let(:raw_query_result) do
          [
            {
              'query id' => query.id,
              'query text' => query.text,
              'fallback behavior' => 'fallback allowed',
              'cache name' => query.name,
              'count' => query.count.to_s,
            },
          ]
        end
        let(:expected_output) { query }
      end
    end

    context 'when a cached query with the given ID does not exist' do
      let(:query_id) { 'fake query id' }

      before do
        allow(Readyset).
          to receive(:raw_query).
          with('SHOW CACHES WHERE query_id = ?', query_id).
          and_raise(Readyset::Query::NotFoundError.new(query_id))

        begin
          subject
        rescue Readyset::Query::NotFoundError
          nil
        end
      end

      it 'invokes "SHOW CACHES" on Readyset' do
        expect(Readyset).
          to have_received(:raw_query).
          with('SHOW CACHES WHERE query_id = ?', query_id)
      end

      it 'raises a Readyset::Query::NotFoundError' do
        expect { subject }.to raise_error(Readyset::Query::NotFoundError)
      end
    end
  end

  describe '.new' do
    subject { Readyset::Query::CachedQuery.new(**attrs) }

    let(:attrs) { attributes_for(:cached_query) }

    it "assigns the object's attributes correctly" do
      expect(subject.id).to eq('q_eafb620c78f5b9ac')
      expect(subject.always).to eq(false)
      expect(subject.text).to eq('SELECT * FROM "t" WHERE ("x" = $1)')
      expect(subject.name).to eq('q_eafb620c78f5b9ac')
      expect(subject.count).to eq(5)
    end
  end

  describe '#always?' do
    subject { query.always? }

    context 'when the query supports fallback' do
      let(:query) { build(:cached_query) }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end

    context 'when the query does not support fallback' do
      let(:query) { build(:cached_query, always: true) }

      it 'returns true' do
        is_expected.to eq(true)
      end
    end
  end

  describe '#drop!' do
    subject { query.drop! }

    let(:query) { build(:cached_query) }

    before do
      allow(Readyset::Query::ProxiedQuery).to receive(:find).with(id: query.id).
        and_return(build(:proxied_query))
      allow(Readyset).to receive(:drop_cache!).with(name_or_id: query.id)

      subject
    end

    it 'invokes Readyset.drop_cache!' do
      expect(Readyset).to have_received(:drop_cache!).with(name_or_id: query.id)
    end

    it 'returns the newly-proxied query' do
      is_expected.to eq(build(:proxied_query))
    end
  end
end
