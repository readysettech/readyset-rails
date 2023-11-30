# frozen_string_literal: true

# require 'spec_helper'

RSpec.describe ReadySet::Query do
  describe '.all_cached' do
    subject { ReadySet::Query.all_cached }

    let(:cached_queries) { [cached_query_attributes] }

    before do
      allow(ReadySet).to receive(:raw_query).with('SHOW CACHES').and_return(cached_queries)
      subject
    end

    it 'invokes "SHOW CACHES" on ReadySet' do
      expect(ReadySet).to have_received(:raw_query).with('SHOW CACHES')
    end

    it 'returns the cached queries' do
      expect(subject.size).to eq(1)
      expect_queries_to_be_equal(subject[0], cached_query)
    end
  end

  describe '.all_seen_but_not_cached' do
    subject { ReadySet::Query.all_seen_but_not_cached }

    let(:seen_but_not_cached_queries) { [seen_but_not_cached_query_attributes] }

    before do
      allow(ReadySet).to receive(:raw_query).with('SHOW PROXIED QUERIES').
        and_return(seen_but_not_cached_queries)

      subject
    end

    it 'invokes "SHOW PROXIED QUERIES" on ReadySet' do
      expect(ReadySet).to have_received(:raw_query).with('SHOW PROXIED QUERIES')
    end

    it 'returns the seen-but-not-cached queries' do
      expect(subject.size).to eq(1)
      expect_queries_to_be_equal(subject[0], seen_but_not_cached_query)
    end
  end

  describe '.cache_all_supported!' do
    subject { ReadySet::Query.cache_all_supported!(always: true) }

    let(:queries) { supported_queries + unsupported_or_pending_queries }
    let(:supported_queries) do
      [
        seen_but_not_cached_query,
        ReadySet::Query.new({
          'query id' => 'q_8892818e62c34ecd',
          'proxied query' => 'SELECT * FROM "t" WHERE ("y" = $1)',
          'readyset supported' => 'yes',
          'count' => 5,
        }),
      ]
    end
    let(:unsupported_or_pending_queries) do
      [
        ReadySet::Query.new(
          'query id' => 'q_f9bfc11a043b2f75',
          'proxied query' => 'SHOW TIME ZONE',
          'readyset supported' => 'unsupported',
          'count' => 5,
        ),
        ReadySet::Query.new(
          'query id' => 'q_d7cbfb8a03d589cf',
          'proxied query' => 'SELECT * FROM "t" WHERE ("x" < 1)',
          'readyset supported' => 'pending',
          'count' => 5,
        ),
      ]
    end

    before do
      allow(ReadySet::Query).to receive(:all_seen_but_not_cached).and_return(queries)
    end

    context 'when every ReadySet::Query#cache! invocation succeeds' do
      before do
        queries.each { |query| allow(query).to receive(:cache!).with(always: true) }
        subject
      end

      it 'invokes ReadySet::Query#cache! on every supported query with the given "always" ' \
          'parameter' do
        supported_queries.each do |query|
          expect(query).to have_received(:cache!).with(always: true)
        end
      end

      it 'does not invoke ReadySet::Query#cache! on any unsupported or pending queries' do
        unsupported_or_pending_queries.each do |query|
          expect(query).not_to have_received(:cache!)
        end
      end

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when one of the ReadySet::Query#cache! invocations fails' do
      before do
        allow(queries[0]).to receive(:cache!).and_raise(StandardError)
        allow(queries[1]).to receive(:cache!)

        begin
          subject
        rescue StandardError
          nil
        end
      end

      it 'raises the error raised by the ReadySet::Query#cache! invocation' do
        expect { subject }.to raise_error(StandardError)
      end

      it 'invokes ReadySet::Query#cache! on the queries in the list up to and including the ' \
          'query that caused the error with the given "always" parameter' do
        expect(queries[0]).to have_received(:cache!).with(always: true)
      end

      it 'does not invoke ReadySet::Query#cache! on any of the queries in the list after the ' \
          'query that caused the error' do
        expect(queries[1]).not_to have_received(:cache!)
      end
    end
  end

  describe '.drop_all_caches!' do
    subject { ReadySet::Query.drop_all_caches! }

    before do
      allow(ReadySet).to receive(:raw_query).with('DROP ALL CACHES')

      subject
    end

    it 'invokes "DROP ALL CACHES" against ReadySet' do
      expect(ReadySet).to have_received(:raw_query).with('DROP ALL CACHES')
    end

    it 'returns nil' do
      is_expected.to be_nil
    end
  end

  describe '.find' do
    subject { ReadySet::Query.find(query_id) }

    context 'when a cached query with the given ID exists' do
      let(:query) { cached_query_attributes }

      before do
        allow(ReadySet).
          to receive(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id).
          and_raise(ReadySet::Query::NotFoundError.new(query_id))

        allow(ReadySet).
          to receive(:raw_query).
          with('SHOW CACHES WHERE query_id = ?', query_id).
          and_return([query])

        subject
      end

      it 'invokes "SHOW PROXIED QUERIES" on ReadySet' do
        expect(ReadySet).
          to have_received(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id)
      end

      it 'invokes "SHOW CACHES" on ReadySet' do
        expect(ReadySet).
          to have_received(:raw_query).
          with('SHOW CACHES WHERE query_id = ?', query_id)
      end

      it 'returns the query' do
        expect_queries_to_be_equal(subject, cached_query)
      end
    end

    context 'when a seen-but-not-cached query with the given ID exists' do
      let(:query) { seen_but_not_cached_query_attributes }

      before do
        allow(ReadySet).
          to receive(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id).
          and_return([query])

        subject
      end

      it 'invokes "SHOW PROXIED QUERIES" on ReadySet' do
        expect(ReadySet).
          to have_received(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id)
      end

      it 'returns the query' do
        expect_queries_to_be_equal(subject, seen_but_not_cached_query)
      end
    end

    context 'when no query with the given ID exists' do
      before do
        allow(ReadySet).
          to receive(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id).
          and_raise(ReadySet::Query::NotFoundError.new(query_id))

        allow(ReadySet).
          to receive(:raw_query).
          with('SHOW CACHES WHERE query_id = ?', query_id).
          and_raise(ReadySet::Query::NotFoundError.new(query_id))

        begin
          subject
        rescue ReadySet::Query::NotFoundError
          nil
        end
      end

      it 'invokes "SHOW PROXIED QUERIES" on ReadySet' do
        expect(ReadySet).
          to have_received(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id)
      end

      it 'invokes "SHOW CACHES" on ReadySet' do
        expect(ReadySet).
          to have_received(:raw_query).
          with('SHOW CACHES WHERE query_id = ?', query_id)
      end

      it 'raises a ReadySet::Query::NotFoundError' do
        expect { subject }.to raise_error(ReadySet::Query::NotFoundError)
      end
    end
  end

  describe '.find_cached' do
    subject { ReadySet::Query.find_cached(query_id) }

    context 'when a cached query with the given ID exists' do
      let(:query) { cached_query_attributes }

      before do
        allow(ReadySet).
          to receive(:raw_query).
          with('SHOW CACHES WHERE query_id = ?', query_id).
          and_return([query])

        subject
      end

      it 'invokes "SHOW CACHES" on ReadySet' do
        expect(ReadySet).
          to have_received(:raw_query).
          with('SHOW CACHES WHERE query_id = ?', query_id)
      end

      it 'returns the query' do
        expect_queries_to_be_equal(subject, cached_query)
      end
    end

    context 'when a cached query with the given ID does not exist' do
      before do
        allow(ReadySet).
          to receive(:raw_query).
          with('SHOW CACHES WHERE query_id = ?', query_id).
          and_raise(ReadySet::Query::NotFoundError.new(query_id))

        begin
          subject
        rescue ReadySet::Query::NotFoundError
          nil
        end
      end

      it 'invokes "SHOW CACHES" on ReadySet' do
        expect(ReadySet).
          to have_received(:raw_query).
          with('SHOW CACHES WHERE query_id = ?', query_id)
      end

      it 'raises a ReadySet::Query::NotFoundError' do
        expect { subject }.to raise_error(ReadySet::Query::NotFoundError)
      end
    end
  end

  describe '.find_seen_but_not_cached' do
    subject { ReadySet::Query.find_seen_but_not_cached(query_id) }

    context 'when a seen-but-not-cached query with the given ID exists' do
      before do
        allow(ReadySet).
          to receive(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id).
          and_return([seen_but_not_cached_query_attributes])

        subject
      end

      it 'invokes "SHOW PROXIED QUERIES" on ReadySet' do
        expect(ReadySet).
          to have_received(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id)
      end

      it 'returns the query' do
        expect_queries_to_be_equal(subject, seen_but_not_cached_query)
      end
    end

    context 'when a seen-but-not-cached query with the given ID does not exist' do
      before do
        allow(ReadySet).
          to receive(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id).
          and_raise(ReadySet::Query::NotFoundError.new(query_id))

        begin
          subject
        rescue ReadySet::Query::NotFoundError
          nil
        end
      end

      it 'invokes "SHOW PROXIED QUERIES" on ReadySet' do
        expect(ReadySet).
          to have_received(:raw_query).
          with('SHOW PROXIED QUERIES WHERE query_id = ?', query_id)
      end

      it 'raises a ReadySet::Query::NotFoundError' do
        expect { subject }.to raise_error(ReadySet::Query::NotFoundError)
      end
    end
  end

  describe '.new' do
    subject { ReadySet::Query.new(attrs) }

    context 'when given the attributes from a cached query' do
      let(:attrs) { cached_query_attributes }

      it "assigns the object's attributes correctly" do
        expect_queries_to_be_equal(subject, cached_query)
      end
    end

    context 'when given the attributes from a seen-but-not-cached query' do
      let(:attrs) { seen_but_not_cached_query_attributes }

      it "assigns the object's attributes correctly" do
        expect_queries_to_be_equal(subject, seen_but_not_cached_query)
      end
    end
  end

  describe '#cache!' do
    context 'when the query is already cached' do
      subject { query.cache! }

      let(:query) { cached_query }

      it 'raises a ReadySet::Query::CacheAlreadyExistsError' do
        expect { subject }.to raise_error(ReadySet::Query::CacheAlreadyExistsError)
      end
    end

    context 'when the query is unsupported' do
      subject { query.cache! }

      let(:query) do
        ReadySet::Query.new(
          'query id' => 'q_f9bfc11a043b2f75',
          'proxied query' => 'SHOW TIME ZONE',
          'readyset supported' => 'unsupported',
          'count' => 5,
        )
      end

      it 'raises a ReadySet::Query::UnsupportedError' do
        expect { subject }.to raise_error(ReadySet::Query::UnsupportedError)
      end
    end

    context 'when the query is supported and not cached' do
      let(:query) { seen_but_not_cached_query }

      before do
        allow(ReadySet).to receive(:raw_query).with(*create_cache_statement)
        allow(query).to receive(:reload)

        subject
      end

      context 'when only the "always" parameter is passed' do
        subject { query.cache!(always: true) }

        let(:create_cache_statement) { ['CREATE CACHE ALWAYS FROM %s', query_id] }

        it 'invokes "CREATE CACHE ALWAYS FROM <query_id>" on ReadySet' do
          expect(ReadySet).to have_received(:raw_query).with(*create_cache_statement)
        end

        it 'invokes ReadySet::Query#reload' do
          expect(query).to have_received(:reload)
        end

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      context 'when only the "name" parameter is passed' do
        subject { query.cache!(name: name) }

        let(:create_cache_statement) { ['CREATE CACHE ? FROM %s', name, query_id] }
        let(:name) { 'test cache' }

        it 'invokes "CREATE CACHE <name> FROM <query_id>" on ReadySet' do
          expect(ReadySet).to have_received(:raw_query).with(*create_cache_statement)
        end

        it 'invokes Query#reload' do
          expect(query).to have_received(:reload)
        end

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      context 'when both the "always" and "name" parameters are passed' do
        subject { query.cache!(always: true, name: name) }

        let(:create_cache_statement) { ['CREATE CACHE ALWAYS ? FROM %s', name, query_id] }
        let(:name) { 'test cache' }

        it 'invokes "CREATE CACHE ALWAYS <name> FROM <query_id>" on ReadySet' do
          expect(ReadySet).to have_received(:raw_query).with(*create_cache_statement)
        end

        it 'invokes Query#reload' do
          expect(query).to have_received(:reload)
        end
      end

      context 'when neither the "always" nor the "name" parameters are passed' do
        subject { query.cache! }

        let(:create_cache_statement) { ['CREATE CACHE FROM %s', query_id] }

        it 'invokes "CREATE CACHE FROM <query_id>" on ReadySet' do
          expect(ReadySet).to have_received(:raw_query).with(*create_cache_statement)
        end

        it 'invokes Query#reload' do
          expect(query).to have_received(:reload)
        end

        it 'returns nil' do
          is_expected.to be_nil
        end
      end
    end
  end

  describe '#cached?' do
    context 'when the query has a cache name' do
      subject { cached_query }

      it 'returns true' do
        expect(subject.cached?).to eq(true)
      end
    end

    context 'when the query does not have a cache name' do
      subject { seen_but_not_cached_query }

      it 'returns false' do
        expect(subject.cached?).to eq(false)
      end
    end
  end

  describe '#drop_cache!' do
    subject { query.drop_cache! }

    context 'when the query is cached' do
      let(:query) { cached_query }

      before do
        allow(ReadySet).to receive(:raw_query).with('DROP CACHE %s', query_id)
        allow(query).to receive(:reload)

        subject
      end

      it 'invokes "DROP CACHE <query_id> on ReadySet' do
        expect(ReadySet).to have_received(:raw_query).with('DROP CACHE %s', query_id)
      end

      it 'invokes ReadySet::Query#reload' do
        expect(query).to have_received(:reload)
      end

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when the query is not cached' do
      let(:query) { seen_but_not_cached_query }

      it 'raises a ReadySet::Query::NotCachedError' do
        expect { subject }.to raise_error(ReadySet::Query::NotCachedError)
      end
    end
  end

  describe '#fallback_allowed?' do
    subject { ReadySet::Query.new(attrs).fallback_allowed? }

    context 'when the query is not cached' do
      let(:attrs) { seen_but_not_cached_query_attributes }

      it 'raises a ReadySet::Query::NotCachedError' do
        expect { subject }.to raise_error(ReadySet::Query::NotCachedError)
      end
    end

    context 'when the query is cached' do
      context 'when the query supports fallback' do
        let(:attrs) { cached_query_attributes }

        it 'returns true' do
          is_expected.to eq(true)
        end
      end

      context 'when the query does not support fallback' do
        let(:attrs) do
          {
            'query id' => 'q_eafb620c78f5b9ac',
            'query text' => 'SELECT * FROM "t" WHERE ("x" = $1)',
            'cache name' => 'q_eafb620c78f5b9ac',
            'fallback behavior' => 'no fallback',
            'count' => 5,
          }
        end

        it 'returns false' do
          is_expected.to eq(false)
        end
      end
    end
  end

  describe '#reload' do
    subject { query.reload }

    let(:query) do
      attrs = {
        'query id' => query_id,
        'proxied query' => 'SELECT * FROM "t" WHERE ("x" = $1)',
        'readyset supported' => 'yes',
        'count' => 5,
      }

      ReadySet::Query.new(attrs)
    end

    let(:query_id) { 'q_eafb620c78f5b9ac' }

    before do
      attrs = {
        'query id' => query_id,
        'query text' => 'SELECT * FROM "t" WHERE ("x" = $1)',
        'cache name' => query_id,
        'fallback behavior' => 'fallback allowed',
        'count' => 0,
      }
      updated_query = ReadySet::Query.new(attrs)

      allow(ReadySet::Query).to receive(:find).with(query_id).and_return(updated_query)

      subject
    end

    it 'updates the attributes of the query with updated data from ReadySet' do
      expect(query.id).to eq(query_id)
      expect(query.supported).to eq(:yes)
      expect(query.cache_name).to eq(query_id)
      expect(query.fallback_allowed?).to eq(true)
      expect(query.count).to eq(0)
    end
  end

  private

  def cached_query_attributes
    {
      'query id' => query_id,
      'query text' => 'SELECT * FROM "t" WHERE ("x" = $1)',
      'cache name' => query_id,
      'fallback behavior' => 'fallback allowed',
      'count' => 5,
    }
  end

  def cached_query
    ReadySet::Query.new(cached_query_attributes)
  end

  def query_id
    'q_eafb620c78f5b9ac'
  end

  def seen_but_not_cached_query_attributes
    {
      'query id' => query_id,
      'proxied query' => 'SELECT * FROM "t" WHERE ("x" = $1)',
      'readyset supported' => 'yes',
      'count' => 5,
    }
  end

  def seen_but_not_cached_query
    ReadySet::Query.new(seen_but_not_cached_query_attributes)
  end

  def expect_queries_to_be_equal(query1, query2)
    query1.id == query2.id &&
      query1.text == query2.text &&
      query1.supported == query2.supported &&
      query1.cache_name == query2.cache_name &&
      query1.send(:fallback_behavior) == query2.send(:fallback_behavior) &&
      query1.count == query2.count
  end
end
