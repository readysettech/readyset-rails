# frozen_string_literal: true

# require 'spec_helper'

RSpec.describe ReadySet::Query do
  describe '.all_cached' do
    subject { ReadySet::Query.all_cached }

    let(:cached_queries) do
      [
        {
          'query id' => 'q_eafb620c78f5b9ac',
          'query text' => 'SELECT * FROM "t" WHERE ("x" = $1)',
          'cache name' => 'q_eafb620c78f5b9ac',
          'fallback behavior' => 'fallback allowed',
          'count' => 5,
        },
      ]
    end

    before do
      allow(ReadySet).to receive(:raw_query).with('SHOW CACHES').and_return(cached_queries)
      subject
    end

    it 'invokes "SHOW CACHES" on ReadySet' do
      expect(ReadySet).to have_received(:raw_query).with('SHOW CACHES')
    end

    it 'returns the cached queries' do
      expect(subject[0].id).to eq('q_eafb620c78f5b9ac')
      expect(subject[0].text).to eq('SELECT * FROM "t" WHERE ("x" = $1)')
      expect(subject[0].cache_name).to eq('q_eafb620c78f5b9ac')
      expect(subject[0].supported).to eq(:yes)
      expect(subject[0].count).to eq(5)
    end
  end

  describe '.all_seen_but_not_cached' do
    subject { ReadySet::Query.all_seen_but_not_cached }

    let(:seen_but_not_cached_queries) do
      [
        {
          'query id' => 'q_eafb620c78f5b9ac',
          'proxied query' => 'SELECT * FROM "t" WHERE ("x" = $1)',
          'readyset supported' => 'yes',
          'count' => 5,
        },
      ]
    end

    before do
      allow(ReadySet).to receive(:raw_query).with('SHOW PROXIED QUERIES').
        and_return(seen_but_not_cached_queries)

      subject
    end

    it 'invokes "SHOW PROXIED QUERIES" on ReadySet' do
      expect(ReadySet).to have_received(:raw_query).with('SHOW PROXIED QUERIES')
    end

    it 'returns the seen-but-not-cached queries' do
      expect(subject[0].id).to eq('q_eafb620c78f5b9ac')
      expect(subject[0].text).to eq('SELECT * FROM "t" WHERE ("x" = $1)')
      expect(subject[0].cache_name).to be_nil
      expect(subject[0].supported).to eq(:yes)
      expect(subject[0].count).to eq(5)
    end
  end

  describe '.find' do
    subject { ReadySet::Query.find(query_id) }

    let(:query_id) { 'q_eafb620c78f5b9ac' }

    context 'when a cached query with the given ID exists' do
      let(:query) do
        {
          'query id' => query_id,
          'query text' => 'SELECT * FROM "t" WHERE ("x" = $1)',
          'cache name' => query_id,
          'fallback behavior' => 'fallback allowed',
          'count' => 5,
        }
      end

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
        expect(subject.id).to eq(query_id)
        expect(subject.text).to eq('SELECT * FROM "t" WHERE ("x" = $1)')
        expect(subject.cache_name).to eq(query_id)
        expect(subject.supported).to eq(:yes)
        expect(subject.count).to eq(5)
      end
    end

    context 'when a seen-but-not-cached query with the given ID exists' do
      let(:query) do
        {
          'query id' => 'q_eafb620c78f5b9ac',
          'proxied query' => 'SELECT * FROM "t" WHERE ("x" = $1)',
          'readyset supported' => 'yes',
          'count' => 5,
        }
      end

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
        expect(subject.id).to eq(query_id)
        expect(subject.text).to eq('SELECT * FROM "t" WHERE ("x" = $1)')
        expect(subject.cache_name).to be_nil
        expect(subject.supported).to eq(:yes)
        expect(subject.count).to eq(5)
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

    let(:query_id) { 'q_eafb620c78f5b9ac' }

    context 'when a cached query with the given ID exists' do
      let(:query) do
        {
          'query id' => query_id,
          'query text' => 'SELECT * FROM "t" WHERE ("x" = $1)',
          'cache name' => query_id,
          'fallback behavior' => 'fallback allowed',
          'count' => 5,
        }
      end

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
        expect(subject.id).to eq(query_id)
        expect(subject.text).to eq('SELECT * FROM "t" WHERE ("x" = $1)')
        expect(subject.cache_name).to eq(query_id)
        expect(subject.supported).to eq(:yes)
        expect(subject.count).to eq(5)
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

    let(:query_id) { 'q_eafb620c78f5b9ac' }

    context 'when a seen-but-not-cached query with the given ID exists' do
      let(:query) do
        {
          'query id' => query_id,
          'proxied query' => 'SELECT * FROM "t" WHERE ("x" = $1)',
          'readyset supported' => 'yes',
          'count' => 5,
        }
      end

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
        expect(subject.id).to eq(query_id)
        expect(subject.text).to eq('SELECT * FROM "t" WHERE ("x" = $1)')
        expect(subject.cache_name).to be_nil
        expect(subject.supported).to eq(:yes)
        expect(subject.count).to eq(5)
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
      let(:attrs) do
        {
          'query id' => 'q_eafb620c78f5b9ac',
          'query text' => 'SELECT * FROM "t" WHERE ("x" = $1)',
          'cache name' => 'test cache',
          'fallback behavior' => 'fallback allowed',
          'count' => 5,
        }
      end

      it "assigns the object's attributes correctly" do
        expect(subject.id).to eq('q_eafb620c78f5b9ac')
        expect(subject.text).to eq('SELECT * FROM "t" WHERE ("x" = $1)')
        expect(subject.cache_name).to eq('test cache')
        expect(subject.send(:fallback_behavior)).to eq(:'fallback allowed')
        expect(subject.count).to eq(5)
      end
    end

    context 'when given the attributes from a seen-but-not-cached query' do
      let(:attrs) do
        {
          'query id' => 'q_eafb620c78f5b9ac',
          'proxied query' => 'SELECT * FROM "t" WHERE ("x" = $1)',
          'readyset supported' => 'yes',
          'count' => 5,
        }
      end

      it "assigns the object's attributes correctly" do
        expect(subject.id).to eq('q_eafb620c78f5b9ac')
        expect(subject.text).to eq('SELECT * FROM "t" WHERE ("x" = $1)')
        expect(subject.cache_name).to be_nil
        expect(subject.send(:fallback_behavior)).to be_nil
        expect(subject.count).to eq(5)
      end
    end
  end

  describe '#cached?' do
    context 'when the query has a cache name' do
      subject do
        attrs = {
          'query id' => 'q_eafb620c78f5b9ac',
          'query text' => 'SELECT * FROM "t" WHERE ("x" = $1)',
          'cache name' => 'q_eafb620c78f5b9ac',
          'fallback behavior' => 'fallback allowed',
          'count' => 5,
        }

        ReadySet::Query.new(attrs)
      end

      it 'returns true' do
        expect(subject.cached?).to eq(true)
      end
    end

    context 'when the query does not have a cache name' do
      subject do
        attrs = {
          'query id' => 'q_eafb620c78f5b9ac',
          'proxied query' => 'SELECT * FROM "t" WHERE ("x" = $1)',
          'readyset supported' => 'yes',
          'count' => 5,
        }

        ReadySet::Query.new(attrs)
      end

      it 'returns false' do
        expect(subject.cached?).to eq(false)
      end
    end
  end

  describe '#fallback_allowed?' do
    subject { ReadySet::Query.new(attrs).fallback_allowed? }

    context 'when the query is not cached' do
      let(:attrs) do
        {
          'query id' => 'q_eafb620c78f5b9ac',
          'proxied query' => 'SELECT * FROM "t" WHERE ("x" = $1)',
          'readyset supported' => 'yes',
          'count' => 5,
        }
      end

      it 'raises a ReadySet::Query::NotCachedError' do
        expect { subject }.to raise_error(ReadySet::Query::NotCachedError)
      end
    end

    context 'when the query is cached' do
      context 'when the query supports fallback' do
        let(:attrs) do
          {
            'query id' => 'q_eafb620c78f5b9ac',
            'query text' => 'SELECT * FROM "t" WHERE ("x" = $1)',
            'cache name' => 'q_eafb620c78f5b9ac',
            'fallback behavior' => 'fallback allowed',
            'count' => 5,
          }
        end

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
end
