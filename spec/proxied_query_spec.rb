# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Readyset::Query::ProxiedQuery do
  describe '.all' do
    it 'returns the list of queries that have been proxied by ReadySet' do
      query = build_and_execute_proxied_query(:proxied_query, supported: :pending)

      queries = Readyset::Query::ProxiedQuery.all

      expect(queries).to eq([query])
    end
  end

  describe '.cache_all_supported!' do
    context 'when every ProxiedQuery#cache! invocation succeeds' do
      it 'creates all the caches on ReadySet' do
        build_and_execute_proxied_query(:proxied_query)
        build_and_execute_proxied_query(:proxied_query_2)

        eventually do
          Readyset::Query::ProxiedQuery.all.all? { |query| query.supported == :yes }
        end

        results = Readyset::Query::ProxiedQuery.cache_all_supported!

        expected_cached_queries = [build(:cached_query).text, build(:cached_query_2).text].sort
        cached_queries = results.map(&:text).sort
        expect(cached_queries).to eq(expected_cached_queries)
      end

      it 'does not invoke ProxiedQuery#cache! on any unsupported or pending queries' do
        build_and_execute_proxied_query(:proxied_query)
        eventually do
          Readyset::Query::ProxiedQuery.all.all? { |query| query.supported == :yes }
        end
        query = build_and_execute_proxied_query(:proxied_query_2, supported: :pending)

        cached = Readyset::Query::ProxiedQuery.cache_all_supported!
        proxied = Readyset::Query::ProxiedQuery.all

        expect(cached).to eq([build(:cached_query)])
        expect(proxied).to eq([query])
      end
    end

    context 'when one of the ProxiedQuery#cache! invocations fails' do
      it 'raises the error raised by the ProxiedQuery#cache! invocation' do
        setup

        expect { Readyset::Query::ProxiedQuery.cache_all_supported! }.
          to raise_error(StandardError)
      end

      it 'creates caches for the queries in the list up to the query that caused the error' do
        setup

        begin
          Readyset::Query::ProxiedQuery.cache_all_supported!
        rescue
        end

        cached = Readyset::Query::CachedQuery.all
        expect(cached).to eq([build(:cached_query)])
      end

      def setup
        query_1 = build_and_execute_proxied_query(:proxied_query)
        query_2 = build_and_execute_proxied_query(:proxied_query_2)
        query_3 = build_and_execute_proxied_query(:proxied_query_3)

        allow(Readyset::Query::ProxiedQuery).to receive(:all).
          and_return([query_1, query_2, query_3])
        allow(query_2).to receive(:cache!).and_raise(StandardError)
      end
    end
  end

  describe '.find' do
    context 'when a proxied query with the given ID exists' do
      it 'returns the proxied query' do
        expected_query = build_and_execute_proxied_query(:proxied_query, supported: :pending)

        query = Readyset::Query::ProxiedQuery.find(expected_query.id)

        expect(query).to eq(expected_query)
      end
    end

    context 'when a proxied query with the given ID does not exist' do
      it 'raises a Readyset::Query::NotFoundError' do
        expect { Readyset::Query::ProxiedQuery.find(build(:proxied_query).id) }.
          to raise_error(Readyset::Query::NotFoundError)
      end
    end
  end

  describe '.new' do
    it "assigns the object's attributes correctly" do
      query = Readyset::Query::ProxiedQuery.new(**attributes_for(:proxied_query))

      expect(query.count).to eq(0)
      expect(query.id).to eq('q_4f3fb9ad8f73bc0c')

      expected_query =
        <<~SQL.chomp
          SELECT
            "cats"."breed"
          FROM
            "cats"
          WHERE
            ("cats"."name" = $1)
        SQL
      expect(query.text).to eq(expected_query)
    end
  end

  describe '#cache!' do
    context 'when the query is unsupported' do
      it 'raises a ProxiedQuery::UnsupportedError' do
        query = build(:unsupported_proxied_query)

        expect { query.cache! }.to raise_error(Readyset::Query::ProxiedQuery::UnsupportedError)
      end
    end

    context 'when the query is supported' do
      it 'creates the cache on ReadySet' do
        query = build_and_execute_proxied_query(:proxied_query)

        query.cache!

        caches = Readyset::Query::CachedQuery.all
        expect(caches).to eq([build(:cached_query)])
      end

      it 'returns the cached query' do
        query = build_and_execute_proxied_query(:proxied_query)

        cache = query.cache!

        caches = Readyset::Query::CachedQuery.all
        expect(caches).to eq([cache])
      end
    end
  end
end
