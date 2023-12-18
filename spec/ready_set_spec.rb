# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Readyset do
  it 'has a version number' do
    expect(Readyset::VERSION).not_to be nil
  end

  describe '.configuration' do
    it 'returns the current configuration object' do
      expect(Readyset.configuration).to be_an_instance_of(Readyset::Configuration)
    end

    it 'is aliased as .config' do
      expect(Readyset.config).to eq(Readyset.configuration)
    end
  end

  describe '.create_cache!' do
    context 'when given neither a SQL string nor an ID' do
      it 'raises an ArgumentError' do
        expect { Readyset.create_cache! }.to raise_error(ArgumentError)
      end
    end

    context 'when given both a SQL string and an ID' do
      it 'raises an ArgumentError' do
        proxied_query = build(:proxied_query)

        expect { Readyset.create_cache!(sql: proxied_query.text, id: proxied_query.id) }.
          to raise_error(ArgumentError)
      end
    end

    context 'when given a SQL string but not an ID' do
      it 'creates a cache using the given SQL string' do
        Readyset.create_cache!(sql: build(:proxied_query).text)

        expected_cache = build(:cached_query)
        cache = Readyset::Query::CachedQuery.all.first
        expect(cache.id).to eq(expected_cache.id)
        expect(cache.text).to eq(expected_cache.text)
      end
    end

    context 'when given an ID but not a SQL string' do
      it 'creates a cache using the given ID' do
        # We invoke the query here so it shows up in SHOW PROXIED QUERIES, which is a prerequisite
        # for creating a cache via a query ID
        proxied_query = build_and_execute_proxied_query(:proxied_query)
        Readyset.create_cache!(id: proxied_query.id)

        expected_cache = build(:cached_query)
        cache = Readyset::Query::CachedQuery.all.first
        expect(cache.id).to eq(expected_cache.id)
        expect(cache.text).to eq(expected_cache.text)
      end

      it 'quotes the ID as an identifier' do
        allow(Readyset).to receive(:raw_query).with('CREATE CACHE FROM "test_id"')

        Readyset.create_cache!(id: 'test_id')

        expect(Readyset).to have_received(:raw_query).with('CREATE CACHE FROM "test_id"')
      end
    end

    context 'when only the "always" parameter is passed' do
      it 'creates a cache with the "always" parameter on ReadySet' do
        Readyset.create_cache!(sql: build(:proxied_query).text, always: true)

        cache = Readyset::Query::CachedQuery.all.first
        expect(cache.always).to eq(true)
      end
    end

    context 'when only the "name" parameter is passed' do
      it 'creates a cache with a name on ReadySet' do
        Readyset.create_cache!(sql: build(:proxied_query).text, name: 'test_name')

        cache = Readyset::Query::CachedQuery.all.first
        expect(cache.name).to eq('test_name')
      end

      it 'quotes the name as an identifier' do
        allow(Readyset).to receive(:raw_query).with('CREATE CACHE "test_name" FROM "test_id"')

        Readyset.create_cache!(id: 'test_id', name: 'test_name')

        expect(Readyset).to have_received(:raw_query).
          with('CREATE CACHE "test_name" FROM "test_id"')
      end
    end

    context 'when both the "always" and "name" parameters are passed' do
      it 'creates a cache with a name on ReadySet' do
        Readyset.create_cache!(sql: build(:proxied_query).text, always: true, name: 'test_name')

        cache = Readyset::Query::CachedQuery.all.first
        expect(cache.always).to eq(true)
        expect(cache.name).to eq('test_name')
      end

      it 'quotes the name as an identifier' do
        allow(Readyset).to receive(:raw_query).
          with('CREATE CACHE ALWAYS "test_name" FROM "test_id"')

        Readyset.create_cache!(id: 'test_id', always: true, name: 'test_name')

        expect(Readyset).to have_received(:raw_query).
          with('CREATE CACHE ALWAYS "test_name" FROM "test_id"')
      end
    end

    context 'when neither the "always" nor the "name" parameters are passed' do
      it 'creates a cache on ReadySet without the "always" parameter and whose name is the query ' \
          'ID' do
        Readyset.create_cache!(sql: build(:proxied_query).text)

        expected_cache = build(:cached_query)
        cache = Readyset::Query::CachedQuery.all.first
        expect(cache.always).to eq(false)
        expect(cache.name).to eq(expected_cache.id)
      end
    end
  end

  describe '.drop_cache!' do
    it 'drops the cache with the given name' do
      cache_to_drop = build_and_create_cache(:cached_query)
      cache_to_keep = build_and_create_cache(:cached_query_2)
      caches_before_dropping = Readyset::Query::CachedQuery.all
      Readyset.drop_cache!(cache_to_drop.name)
      caches_after_dropping = Readyset::Query::CachedQuery.all

      expect(caches_before_dropping.size).to eq(2)
      expect(caches_after_dropping).to eq([cache_to_keep])
    end

    it 'quotes the name as an identifier' do
      allow(Readyset).to receive(:raw_query).with('DROP CACHE "test_name"')

      Readyset.drop_cache!('test_name')

      expect(Readyset).to have_received(:raw_query).with('DROP CACHE "test_name"')
    end
  end

  describe '.explain' do
    it 'returns a `Readyset::Explain` for the given query' do
      explain = build(:explain)

      result = Readyset.explain(explain.text)

      expect(result).to eq(explain)
    end
  end

  describe '.raw_query' do
    it 'invokes the given query on ReadySet and returns the results' do
      build_and_create_cache(:cached_query)

      results = Readyset.raw_query('SHOW CACHES').to_a

      expected_query =
        <<~SQL.chomp
          SELECT
            "public"."cats"."breed"
          FROM
            "public"."cats"
          WHERE
            ("public"."cats"."name" = $1)
        SQL
      expected_hash = {
        'query id' => 'q_4f3fb9ad8f73bc0c',
        'cache name' => 'q_4f3fb9ad8f73bc0c',
        'query text' => expected_query,
        'fallback behavior' => 'fallback allowed',
        'count' => '0',
      }
      expect(results).to eq([expected_hash])
    end
  end

  describe '.raw_query_sanitize' do
    it 'invokes the given SQL array on ReadySet and returns the results' do
      cache = build_and_create_cache(:cached_query)
      build_and_create_cache(:cached_query_2)

      results = Readyset.raw_query_sanitize('SHOW CACHES WHERE query_id = ?', cache.id).to_a

      expected_query =
        <<~SQL.chomp
          SELECT
            "public"."cats"."breed"
          FROM
            "public"."cats"
          WHERE
            ("public"."cats"."name" = $1)
        SQL
      expected_hash = {
        'query id' => 'q_4f3fb9ad8f73bc0c',
        'cache name' => 'q_4f3fb9ad8f73bc0c',
        'query text' => expected_query,
        'fallback behavior' => 'fallback allowed',
        'count' => '0',
      }
      expect(results).to eq([expected_hash])
    end
  end

  describe '.route' do
    context 'when the healthchecker reports that ReadySet is healthy' do
      before do
        healthchecker = Readyset.send(:healthchecker)
        allow(healthchecker).to receive(:healthy?).and_return(true)
      end

      context 'when an exception is raised during the execution of the block' do
        it 'passes the exception to the healthchecker' do
          error = StandardError.new
          allow(Readyset.send(:healthchecker)).to receive(:process_exception).with(error)
          begin
            Readyset.route do
              raise error
            end
          rescue
          end

          expect(Readyset.send(:healthchecker)).to have_received(:process_exception).with(error)
        end

        it 're-raises the error' do
          expect { Readyset.route { raise StandardError } }.to raise_error(StandardError)
        end
      end

      context 'when prevent_writes is true' do
        context 'when the block contains a write query' do
          it 'raises an ActiveRecord::ReadOnlyError' do
            expect { Readyset.route(prevent_writes: true) { create(:cat) } }.
              to raise_error(ActiveRecord::ReadOnlyError)
          end
        end

        context 'when the block contains a read query' do
          it 'returns the result of the block' do
            expected_cat = create(:cat)

            cat = Readyset.route(prevent_writes: true) do
              Cat.find(expected_cat.id)
            end

            expect(cat).to eq(expected_cat)
          end

          it 'executes the query against ReadySet' do
            expected_cache = build_and_create_cache(:cached_query)

            result = Readyset.route(prevent_writes: true) do
              ActiveRecord::Base.connection.execute('SHOW CACHES').to_a
            end

            expect(result.size).to eq(1)
            cache = Readyset::Query::CachedQuery.
              send(:from_readyset_result, **result.first.symbolize_keys)
            expect(cache).to eq(expected_cache)
          end
        end
      end

      context 'when prevent_writes is false' do
        context 'when the block contains a write query' do
          it 'returns the result of the block' do
            result = Readyset.route(prevent_writes: false) do
              create(:cat)
              'test'
            end

            expect(result).to eq('test')
          end

          it 'executes the write against ReadySet' do
            proxied_query = build(:proxied_query)

            Readyset.route(prevent_writes: false) do
              sanitized = ActiveRecord::Base.
                sanitize_sql_array(['CREATE CACHE FROM %s', proxied_query.text])
              ActiveRecord::Base.connection.execute(sanitized)
            end

            expected_cache = build(:cached_query)
            cache = Readyset::Query::CachedQuery.find(expected_cache.id)
            expect(cache).to eq(expected_cache)
          end
        end

        context 'when the block contains a read query' do
          it 'executes the read against ReadySet' do
            expected_cache = build_and_create_cache(:cached_query)

            results = Readyset.route(prevent_writes: false) do
              ActiveRecord::Base.connection.execute('SHOW CACHES').to_a
            end

            cache = Readyset::Query::CachedQuery.
              send(:from_readyset_result, **results.first.symbolize_keys)
            expect(cache).to eq(expected_cache)
          end
        end
      end
    end

    context 'when the healthchecker reports that ReadySet is unhealthy' do
      before do
        healthchecker = Readyset.send(:healthchecker)
        allow(healthchecker).to receive(:healthy?).and_return(false)
      end

      it 'routes queries to their original destination' do
        Readyset.route(prevent_writes: false) { Cat.where(name: 'whiskers') }

        proxied_queries = Readyset::Query::ProxiedQuery.all
        expect(proxied_queries).to be_empty
      end
    end
    describe '.route' do
      before do
        allow(ActiveRecord::QueryLogs).to receive(:tags).and_return([])
        allow(ActiveRecord::QueryLogs).to receive(:prepend_comment).and_return(true)
      end

      it 'annotates queries with "routed to ReadySet" tag when query_annotations is enabled' do
        # Setup
        Readyset.configure do |config|
          config.query_annotations = true
        end

        log = StringIO.new
        ActiveRecord::Base.logger = Logger.new(STDOUT)

        query = Cat.where(id: 1)
        # Exercise
        Readyset.route { ActiveRecord::Base.connection.execute(query.to_sql) }

        # Verify
        expect(log.read).to include('/* routed to ReadySet */')

        # Teardown
        ActiveRecord::Base.logger = nil
      end

      it 'does not annotate queries when query_annotations is disabled' do
        # Setup
        allow(Readyset.configuration).to receive(:query_annotations).and_return(false)
        log = StringIO.new
        ActiveRecord::Base.logger = Logger.new(STDOUT)

        query = Cat.where(id: 1)

        # Exercise
        Readyset.route { ActiveRecord::Base.connection.execute(query.to_sql) }

        # Verify
        expect(log.string).not_to include('/* routed to ReadySet */')

        # Teardown
        ActiveRecord::Base.logger = nil
      end
    end
  end
end
