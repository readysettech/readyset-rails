# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Readyset::Query::ProxiedQuery do
  describe '.all' do
    subject { Readyset::Query::ProxiedQuery.all }

    it_behaves_like 'a wrapper around a ReadySet SQL extension', 'SHOW PROXIED QUERIES' do
      let(:query) { build(:proxied_query) }
      let(:raw_query_result) do
        [
          {
            'query id' => query.id,
            'proxied query' => query.text,
            'readyset supported' => query.supported.to_s,
            'count' => query.count.to_s,
          },
        ]
      end
      let(:expected_output) { [query] }
    end
  end

  describe '.cache_all_supported!' do
    subject { Readyset::Query::ProxiedQuery.cache_all_supported!(always: true) }

    let(:queries) { supported_queries + unsupported_or_pending_queries }
    let(:cached_query_1) { build(:cached_query, always: true) }
    let(:cached_query_2) do
      build(:cached_query,
            id: 'q_8892818e62c34ecd',
            text: 'SELECT * FROM "t" WHERE ("y" = $1)',
            always: true)
    end
    let(:supported_queries) do
      supported_query_1 = build(:proxied_query)
      allow(supported_query_1).to receive(:cache!).with(always: true).and_return(cached_query_1)

      supported_query_2 = build(:proxied_query,
                                id: 'q_8892818e62c34ecd',
                                text: 'SELECT * FROM "t" WHERE ("y" = $1)')
      allow(supported_query_2).to receive(:cache!).with(always: true).and_return(cached_query_2)

      [supported_query_1, supported_query_2]
    end
    let(:unsupported_or_pending_queries) do
      [
        build(:unsupported_query),
        build(:pending_query),
      ]
    end

    before do
      unsupported_or_pending_queries.each do |query|
        allow(query).to receive(:cache!)
      end

      allow(Readyset::Query::ProxiedQuery).to receive(:all).and_return(queries)
    end

    context 'when every ProxiedQuery#cache! invocation succeeds' do
      before do
        subject
      end

      it 'invokes ProxiedQuery#cache! on every supported query with the given "always" ' \
        'parameter' do
        supported_queries.each do |query|
          expect(query).to have_received(:cache!).with(always: true)
        end
      end

      it 'does not invoke ProxiedQuery#cache! on any unsupported or pending queries' do
        unsupported_or_pending_queries.each do |query|
          expect(query).not_to have_received(:cache!)
        end
      end

      it 'returns the newly-cached queries' do
        is_expected.to eq([cached_query_1, cached_query_2])
      end
    end

    context 'when one of the ProxiedQuery#cache! invocations fails' do
      before do
        allow(queries[0]).to receive(:cache!).and_raise(StandardError)
        allow(queries[1]).to receive(:cache!)

        begin
          subject
        rescue StandardError
          nil
        end
      end

      it 'raises the error raised by the ProxiedQuery#cache! invocation' do
        expect { subject }.to raise_error(StandardError)
      end

      it 'invokes ProxiedQuery#cache! on the queries in the list up to and including ' \
        'the query that caused the error with the given "always" parameter' do
        expect(queries[0]).to have_received(:cache!).with(always: true)
      end

      it 'does not invoke ProxiedQuery#cache! on any of the queries in the list after ' \
        'the query that caused the error' do
        expect(queries[1]).not_to have_received(:cache!)
      end
    end
  end

  describe '.find' do
    subject { Readyset::Query::ProxiedQuery.find(query_id) }

    context 'when a proxied query with the given ID exists' do
      let(:query) { build(:proxied_query) }
      let(:query_id) { query.id }

      it_behaves_like 'a wrapper around a ReadySet SQL extension',
          'SHOW PROXIED QUERIES WHERE query_id = ?' do
        let(:args) { [query_id] }
        let(:raw_query_result) do
          [
            {
              'query id' => query.id,
              'proxied query' => query.text,
              'readyset supported' => query.supported.to_s,
              'count' => query.count.to_s,
            },
          ]
        end
        let(:expected_output) { query }
      end
    end

    context 'when a proxied query with the given ID does not exist' do
      let(:query_id) { 'fake query id' }

      before do
        allow(Readyset).
          to receive(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id).
          and_raise(Readyset::Query::NotFoundError.new(query_id))

        begin
          subject
        rescue Readyset::Query::NotFoundError
          nil
        end
      end

      it 'invokes "SHOW PROXIED QUERIES" on Readyset' do
        expect(Readyset).
          to have_received(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id)
      end

      it 'raises a ProxiedQuery::NotFoundError' do
        expect { subject }.to raise_error(Readyset::Query::NotFoundError)
      end
    end
  end

  describe '.new' do
    subject { Readyset::Query::ProxiedQuery.new(**attrs) }

    let(:attrs) { attributes_for(:proxied_query) }

    it "assigns the object's attributes correctly" do
      expect(subject.id).to eq('q_eafb620c78f5b9ac')
      expect(subject.supported).to eq(:yes)
      expect(subject.count).to eq(5)
      expect(subject.text).to eq('SELECT * FROM "t" WHERE ("x" = $1)')
    end
  end

  describe '#cache!' do
    context 'when the query is unsupported' do
      subject { query.cache! }

      let(:query) { build(:unsupported_query) }

      it 'raises a ProxiedQuery::UnsupportedError' do
        expect { subject }.to raise_error(Readyset::Query::ProxiedQuery::UnsupportedError)
      end
    end

    context 'when the query is supported and not cached' do
      subject { query.cache!(**args) }

      let(:args) { { always: true, name: 'test name' } }
      let(:query) { build(:proxied_query) }

      before do
        allow(Readyset::Query::CachedQuery).to receive(:find).with(query.id).
          and_return(build(:cached_query))
        allow(Readyset).to receive(:create_cache!).with(id: query.id, **args)

        subject
      end

      it 'invokes Readyset.create_cache! with the correct arguments' do
        expect(Readyset).to have_received(:create_cache!).with(id: query.id, **args)
      end

      it 'returns the cached query' do
        is_expected.to eq(build(:cached_query))
      end
    end
  end
end
