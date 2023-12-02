# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Readyset::Query do
  describe '.all_cached' do
    subject { Readyset::Query.all_cached }

    it_behaves_like 'a wrapper around a ReadySet SQL extension', 'SHOW CACHES' do
      let(:raw_query_result) { [attributes_for(:cached_query)] }
      let(:expected_output) { [build(:cached_query)] }
    end
  end

  describe '.all_seen_but_not_cached' do
    subject { Readyset::Query.all_seen_but_not_cached }

    it_behaves_like 'a wrapper around a ReadySet SQL extension', 'SHOW PROXIED QUERIES' do
      let(:raw_query_result) { [attributes_for(:seen_but_not_cached_query)] }
      let(:expected_output) { [build(:seen_but_not_cached_query)] }
    end
  end

  describe '.cache_all_supported!' do
    subject { Readyset::Query.cache_all_supported!(always: true) }

    let(:queries) { supported_queries + unsupported_or_pending_queries }
    let(:supported_queries) do
      [
        build(:seen_but_not_cached_query),
        build(:seen_but_not_cached_query,
              :'query id' => 'q_8892818e62c34ecd',
              :'proxied query' => 'SELECT * FROM "t" WHERE ("y" = $1)')
      ]
    end
    let(:unsupported_or_pending_queries) do
      [
        build(:unsupported_query),
        build(:pending_query),
      ]
    end

    before do
      allow(Readyset::Query).to receive(:all_seen_but_not_cached).and_return(queries)
    end

    context 'when every Readyset::Query#cache! invocation succeeds' do
      before do
        queries.each { |query| allow(query).to receive(:cache!).with(always: true) }
        subject
      end

      it 'invokes Readyset::Query#cache! on every supported query with the given "always" ' \
        'parameter' do
        supported_queries.each do |query|
          expect(query).to have_received(:cache!).with(always: true)
        end
      end

      it 'does not invoke Readyset::Query#cache! on any unsupported or pending queries' do
        unsupported_or_pending_queries.each do |query|
          expect(query).not_to have_received(:cache!)
        end
      end

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when one of the Readyset::Query#cache! invocations fails' do
      before do
        allow(queries[0]).to receive(:cache!).and_raise(StandardError)
        allow(queries[1]).to receive(:cache!)

        begin
          subject
        rescue StandardError
          nil
        end
      end

      it 'raises the error raised by the Readyset::Query#cache! invocation' do
        expect { subject }.to raise_error(StandardError)
      end

      it 'invokes Readyset::Query#cache! on the queries in the list up to and including the ' \
        'query that caused the error with the given "always" parameter' do
        expect(queries[0]).to have_received(:cache!).with(always: true)
      end

      it 'does not invoke Readyset::Query#cache! on any of the queries in the list after the ' \
        'query that caused the error' do
        expect(queries[1]).not_to have_received(:cache!)
      end
    end
  end

  describe '.drop_all_caches!' do
    subject { Readyset::Query.drop_all_caches! }

    it_behaves_like 'a wrapper around a ReadySet SQL extension', 'DROP ALL CACHES'
  end

  describe '.find' do
    subject { Readyset::Query.find(query_id) }

    context 'when a cached query with the given ID exists' do
      let(:query) { build(:cached_query) }
      let(:query_id) { query.id }

      before do
        allow(Readyset).
          to receive(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id).
          and_raise(Readyset::Query::NotFoundError.new(query_id))
      end

      it_behaves_like 'a wrapper around a ReadySet SQL extension',
          'SHOW CACHES WHERE query_id = ?' do
        let(:args) { query_id }
        let(:raw_query_result) { [attributes_for(:cached_query)] }
        let(:expected_output) { query }

        it 'invokes "SHOW PROXIED QUERIES" on ReadySet' do
          expect(Readyset).
            to have_received(:raw_query).
            with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id)
        end
      end
    end

    context 'when a seen-but-not-cached query with the given ID exists' do
      let(:query) { build(:seen_but_not_cached_query) }
      let(:query_id) { query.id }

      it_behaves_like 'a wrapper around a ReadySet SQL extension',
          'SHOW PROXIED QUERIES WHERE query_id = ?' do
        let(:args) { query_id }
        let(:raw_query_result) { [attributes_for(:seen_but_not_cached_query)] }
        let(:expected_output) { query }
      end
    end

    context 'when no query with the given ID exists' do
      let(:query_id) { 'fake query id' }

      before do
        allow(Readyset).
          to receive(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id).
          and_raise(Readyset::Query::NotFoundError.new(query_id))

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

      it 'invokes "SHOW PROXIED QUERIES" on Readyset' do
        expect(Readyset).
          to have_received(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id)
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

  describe '.find_cached' do
    subject { Readyset::Query.find_cached(query_id) }

    context 'when a cached query with the given ID exists' do
      let(:query) { build(:cached_query) }
      let(:query_id) { query.id }

      it_behaves_like 'a wrapper around a ReadySet SQL extension', 'SHOW CACHES WHERE query_id = ?' do
        let(:args) { expected_output.id }
        let(:raw_query_result) { [attributes_for(:cached_query)] }
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

  describe '.find_seen_but_not_cached' do
    subject { Readyset::Query.find_seen_but_not_cached(query_id) }

    context 'when a seen-but-not-cached query with the given ID exists' do
      let(:query) { build(:seen_but_not_cached_query) }
      let(:query_id) { query.id }

      it_behaves_like 'a wrapper around a ReadySet SQL extension',
          'SHOW PROXIED QUERIES WHERE query_id = ?' do
        let(:args) { expected_output.id }
        let(:raw_query_result) { [attributes_for(:seen_but_not_cached_query)] }
        let(:expected_output) { query }
      end
    end

    context 'when a seen-but-not-cached query with the given ID does not exist' do
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

      it 'raises a Readyset::Query::NotFoundError' do
        expect { subject }.to raise_error(Readyset::Query::NotFoundError)
      end
    end
  end

  describe '.new' do
    subject { Readyset::Query.new(attrs) }

    context 'when given the attributes from a cached query' do
      let(:attrs) { attributes_for(:cached_query) }

      it "assigns the object's attributes correctly" do
        expect(subject).to eq(build(:cached_query))
      end
    end

    context 'when given the attributes from a seen-but-not-cached query' do
      let(:attrs) { attributes_for(:seen_but_not_cached_query) }

      it "assigns the object's attributes correctly" do
        expect(subject).to eq(build(:seen_but_not_cached_query))
      end
    end
  end

  describe '#cache!' do
    context 'when the query is already cached' do
      subject { query.cache! }

      let(:query) { build(:cached_query) }

      it 'raises a Readyset::Query::CacheAlreadyExistsError' do
        expect { subject }.to raise_error(Readyset::Query::CacheAlreadyExistsError)
      end
    end

    context 'when the query is unsupported' do
      subject { query.cache! }

      let(:query) { build(:unsupported_query) }

      it 'raises a Readyset::Query::UnsupportedError' do
        expect { subject }.to raise_error(Readyset::Query::UnsupportedError)
      end
    end

    context 'when the query is supported and not cached' do
      let(:query) { build(:seen_but_not_cached_query) }

      before { allow(query).to receive(:reload) }

      context 'when only the "always" parameter is passed' do
        subject { query.cache!(always: true) }

        it_behaves_like 'a wrapper around a ReadySet SQL extension',
            'CREATE CACHE ALWAYS FROM %s' do
          let(:args) { [query.id] }

          it 'invokes Readyset::Query#reload' do
            expect(query).to have_received(:reload)
          end
        end
      end

      context 'when only the "name" parameter is passed' do
        subject { query.cache!(name: name) }

        let(:name) { 'test cache' }

        it_behaves_like 'a wrapper around a ReadySet SQL extension', 'CREATE CACHE ? FROM %s' do
          let(:args) { [name, query.id] }

          it 'invokes Readyset::Query#reload' do
            expect(query).to have_received(:reload)
          end
        end
      end

      context 'when both the "always" and "name" parameters are passed' do
        subject { query.cache!(always: true, name: name) }

        let(:name) { 'test cache' }

        it_behaves_like 'a wrapper around a ReadySet SQL extension', 'CREATE CACHE ALWAYS ? FROM %s' do
          let(:args) { [name, query.id] }

          it 'invokes Readyset::Query#reload' do
            expect(query).to have_received(:reload)
          end
        end
      end

      context 'when neither the "always" nor the "name" parameters are passed' do
        subject { query.cache! }

        it_behaves_like 'a wrapper around a ReadySet SQL extension', 'CREATE CACHE FROM %s' do
          let(:args) { [query.id] }

          it 'invokes Readyset::Query#reload' do
            expect(query).to have_received(:reload)
          end
        end
      end
    end
  end

  describe '#cached?' do
    context 'when the query has a cache name' do
      subject { build(:cached_query) }

      it 'returns true' do
        expect(subject.cached?).to eq(true)
      end
    end

    context 'when the query does not have a cache name' do
      subject { build(:seen_but_not_cached_query) }

      it 'returns false' do
        expect(subject.cached?).to eq(false)
      end
    end
  end

  describe '#drop_cache!' do
    subject { query.drop_cache! }

    context 'when the query is cached' do
      let(:query) { build(:cached_query) }

      before { allow(query).to receive(:reload) }

      it_behaves_like 'a wrapper around a ReadySet SQL extension', 'DROP CACHE %s' do
        let(:args) { [query.id] }

        it 'invokes Readyset::Query#reload' do
          expect(query).to have_received(:reload)
        end
      end
    end

    context 'when the query is not cached' do
      let(:query) { build(:seen_but_not_cached_query) }

      it 'raises a Readyset::Query::NotCachedError' do
        expect { subject }.to raise_error(Readyset::Query::NotCachedError)
      end
    end
  end

  describe '#fallback_allowed?' do
    subject { query.fallback_allowed? }

    context 'when the query is not cached' do
      let(:query) { build(:seen_but_not_cached_query) }

      it 'raises a Readyset::Query::NotCachedError' do
        expect { subject }.to raise_error(Readyset::Query::NotCachedError)
      end
    end

    context 'when the query is cached' do
      context 'when the query supports fallback' do
        let(:query) { build(:cached_query) }

        it 'returns true' do
          is_expected.to eq(true)
        end
      end

      context 'when the query does not support fallback' do
        let(:query) { build(:cached_query, :'fallback behavior' => 'no fallback') }

        it 'returns false' do
          is_expected.to eq(false)
        end
      end
    end
  end

  describe '#reload' do
    subject { query.reload }

    let(:query) { build(:seen_but_not_cached_query) }
    let(:updated_query) { build(:cached_query, :'count' => '0') }

    before do
      allow(Readyset::Query).to receive(:find).with(query.id).and_return(updated_query)

      subject
    end

    it 'updates the attributes of the query with updated data from ReadySet' do
      expect(query).to eq(updated_query)
    end
  end
end
