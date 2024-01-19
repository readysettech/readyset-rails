require 'colorize'
require 'rake'
require 'spec_helper'

load './lib/tasks/readyset.rake'

RSpec.describe 'readyset.rake' do
  before do
    Rake::Task.define_task(:environment)
  end

  describe 'readyset' do
    describe 'caches' do
      it 'prints a table with the caches that currently exist on ReadySet' do
        build_and_create_cache(:cached_query)

        expected_message = <<~TABLE
          +--------------------+--------------------+---------------------------------+--------+-------+
          | id                 | name               | text                            | always | count |
          +--------------------+--------------------+---------------------------------+--------+-------+
          | q_4f3fb9ad8f73bc0c | q_4f3fb9ad8f73bc0c | SELECT                          | false  | 0     |
          |                    |                    |   "public"."cats"."breed"       |        |       |
          |                    |                    | FROM                            |        |       |
          |                    |                    |   "public"."cats"               |        |       |
          |                    |                    | WHERE                           |        |       |
          |                    |                    |   ("public"."cats"."name" = $1) |        |       |
          +--------------------+--------------------+---------------------------------+--------+-------+
        TABLE
        expect { Rake::Task['readyset:caches'].execute }.to output(expected_message).to_stdout
      end

      describe 'drop' do
        context 'when given a cache name as an argument' do
          it 'removes the cache with the given name' do
            cache = build_and_create_cache(:cached_query)

            Rake::Task['readyset:caches:drop'].execute([cache.id])

            caches = Readyset::Query::CachedQuery.all
            expect(caches.size).to eq(0)
          end
        end

        context 'when given no arguments' do
          it 'prints an error message' do
            expect { Rake::Task['readyset:caches:drop'].execute }.
              to output("A cache name must be passed to this task\n").to_stdout
          end
        end
      end

      describe 'drop_all' do
        it 'removes all the caches on ReadySet' do
          build_and_create_cache(:cached_query)
          build_and_create_cache(:cached_query_2)

          Rake::Task['readyset:caches:drop_all'].execute

          caches = Readyset::Query::CachedQuery.all
          expect(caches.size).to eq(0)
        end
      end

      describe 'dump' do
        it 'dumps the current set of caches to a migration file' do
          cache1 = build_and_create_cache(:cached_query, count: nil, id: nil, name: nil)
          cache2 = build_and_create_cache(:cached_query_2, count: nil, id: nil, name: nil)

          Rake::Task['readyset:caches:dump'].execute

          load './spec/internal/db/readyset_caches.rb'
          subclasses = Readyset::Caches.subclasses
          expect(subclasses.size).to eq(1)

          caches = subclasses.first.caches
          expect(caches.size).to eq(2)
          expect(caches).to include(cache1)
          expect(caches).to include(cache2)
        end
      end

      describe 'migrate' do
        after(:each) do
          if File.exist?('./spec/internal/db/readyset_caches.rb')
            File.delete('./spec/internal/db/readyset_caches.rb')
          end
        end

        context "when the migration file contains caches that don't exist on ReadySet" do
          it "creates the caches in the migration file that don't exist on ReadySet" do
            # Setup
            existing_cache = build_and_create_cache(:cached_query)
            cache_to_create = build_and_create_cache(:cached_query_2)

            Rake::Task['readyset:caches:dump'].execute
            cache_to_create.drop!

            allow(STDIN).to receive(:gets).and_return("y\n")

            # Execute
            Rake::Task['readyset:caches:migrate'].execute

            # Verify
            caches = Readyset::Query::CachedQuery.all
            expect(caches.size).to eq(2)
            cache_texts = caches.map(&:text)
            expect(cache_texts).to include(existing_cache.text)
            expect(cache_texts).to include(cache_to_create.text)
          end

          it 'prints the expected output' do
            # Setup
            build_and_create_cache(:cached_query)
            cache_to_create = build_and_create_cache(:cached_query_2)

            Rake::Task['readyset:caches:dump'].execute
            cache_to_create.drop!

            allow(STDIN).to receive(:gets).and_return("y\n")

            # Execute + Verify
            expected_message = "#{'Dropping'.red} 0 caches and #{'creating'.green} 1 caches. " \
              'Continue? (y/n) '
            expect { Rake::Task['readyset:caches:migrate'].execute }.to output(expected_message).
              to_stdout
          end
        end

        context "when ReadySet has caches that don't exist in the migration file" do
          it 'drops the caches that exist on ReadySet that are not in the migration file' do
            existing_cache = build_and_create_cache(:cached_query)
            Rake::Task['readyset:caches:dump'].execute
            build_and_create_cache(:cached_query_2)

            allow(STDIN).to receive(:gets).and_return("y\n")

            # Execute
            Rake::Task['readyset:caches:migrate'].execute

            # Verify
            caches = Readyset::Query::CachedQuery.all
            cache_texts = caches.map(&:text)
            expect(cache_texts).to eq([existing_cache.text])
          end

          it 'prints the expected output' do
            # Setup
            build_and_create_cache(:cached_query)
            Rake::Task['readyset:caches:dump'].execute
            build_and_create_cache(:cached_query_2)

            allow(STDIN).to receive(:gets).and_return("y\n")

            # Execute + Verify
            expected_message = "#{'Dropping'.red} 1 caches and #{'creating'.green} 0 caches. " \
              'Continue? (y/n) '
            expect { Rake::Task['readyset:caches:migrate'].execute }.to output(expected_message).
              to_stdout
          end
        end
      end
    end

    describe 'proxied_queries' do
      it 'prints a table with the queries that ReadySet has proxied' do
        build_and_execute_proxied_query(:proxied_query)

        expected_message = Regexp.new <<~TABLE
          \\+--------------------\\+------------------------\\+-----------\\+-------\\+
          \\| id                 \\| text                   \\| supported \\| count \\|
          \\+--------------------\\+------------------------\\+-----------\\+-------\\+
          \\| q_4f3fb9ad8f73bc0c \\| SELECT                 \\| pending   \\| \\d+[ ]*\\|
          \\|                    \\|   "cats"\\."breed"       \\|           \\| [ ]*\\|
          \\|                    \\| FROM                   \\|           \\| [ ]*\\|
          \\|                    \\|   "cats"               \\|           \\| [ ]*\\|
          \\|                    \\| WHERE                  \\|           \\| [ ]*\\|
          \\|                    \\|   \\("cats"\\."name" = \\$1\\) \\|           \\| [ ]*\\|
          \\+--------------------\\+------------------------\\+-----------\\+-------\\+
        TABLE
        expect { Rake::Task['readyset:proxied_queries'].execute }.to output(expected_message).
          to_stdout
      end

      describe 'cache_all_supported' do
        it 'creates caches for all queries proxied by ReadySet that are supported to be cached' do
          build_and_execute_proxied_query(:proxied_query)
          build_and_execute_proxied_query(:unsupported_proxied_query)

          eventually do
            Readyset::Query::ProxiedQuery.all.all? { |query| query.supported != :pending }
          end

          Rake::Task['readyset:proxied_queries:cache_all_supported'].execute

          expect(Readyset::Query::CachedQuery.all).to eq([build(:cached_query)])
        end
      end

      describe 'drop_all' do
        it 'clears the list of proxied queries on ReadySet' do
          build_and_execute_proxied_query(:proxied_query)
          build_and_execute_proxied_query(:proxied_query_2)

          Rake::Task['readyset:proxied_queries:drop_all'].execute

          proxied = Readyset::Query::ProxiedQuery.all
          expect(proxied).to be_empty
        end
      end
    end

    describe 'status' do
      it "prints a table that shows ReadySet's status" do
        expected_message = Regexp.new <<~TABLE
          \\+----------------------------\\+------------------------\\+
          \\| Database Connection        \\| Connected[ ]*\\|
          \\| Connection Count           \\| \\d+[ ]*\\|
          \\| Snapshot Status            \\| Completed[ ]*\\|
          \\| Maximum Replication Offset \\| \\([0-9A-F]{1,8}\\/[0-9A-F]{1,8}, [0-9A-F]{1,8}\\/[0-9A-F]{1,8}\\) \\|
          \\| Minimum Replication Offset \\| \\([0-9A-F]{1,8}\\/[0-9A-F]{1,8}, [0-9A-F]{1,8}\\/[0-9A-F]{1,8}\\) \\|
          \\| Last started Controller    \\| \\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}[ ]*\\|
          \\| Last completed snapshot    \\| \\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}[ ]*\\|
          \\| Last started replication   \\| \\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}[ ]*\\|
          \\+----------------------------\\+------------------------\\+
        TABLE
        expect { Rake::Task['readyset:status'].execute }.to output(expected_message).
          to_stdout
      end
    end

    describe 'tables' do
      it 'prints a table that shows the tables known to ReadySet' do
        expected_message = Regexp.new <<~TABLE
          \\+---------------------------------\\+-------------\\+-------------\\+
          \\| table                           \\| status      \\| description \\|
          \\+---------------------------------\\+-------------\\+-------------\\+
          (\\| "public"\\."[\\w]*"[ ]*\\| Snapshotted \\|             \\|\n?)*
          \\+---------------------------------\\+-------------\\+-------------\\+
        TABLE

        expect { Rake::Task['readyset:tables'].execute }.to output(expected_message).
          to_stdout
      end
    end
  end
end
