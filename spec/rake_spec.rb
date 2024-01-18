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
      describe 'dump' do
        it 'dumps the current set of caches to a migration file' do
          # Setup
          cache1 = build_and_create_cache(:cached_query, count: nil, id: nil, name: nil)
          cache2 = build_and_create_cache(:cached_query_2, count: nil, id: nil, name: nil)

          # Execute
          Rake::Task['readyset:caches:dump'].execute

          # Verify
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
  end
end
