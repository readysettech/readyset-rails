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
          allow(Readyset::Query::CachedQuery).to receive(:all).
            and_return([build(:cached_query), build(:cached_query_2)])

          # Execute
          Rake::Task['readyset:caches:dump'].execute

          # Verify
          load './spec/internal/db/readyset_caches.rb'
          subclasses = Readyset::Caches.subclasses
          expect(subclasses.size).to eq(1)

          caches = subclasses.first.caches
          expect(caches.size).to eq(2)
          expect(caches).to include(build(:cached_query, count: nil, name: nil))
          expect(caches).to include(build(:cached_query_2, count: nil, name: nil))
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
            cache_to_create = build(:cached_query_2)
            generate_migration_file([build(:cached_query), cache_to_create])

            allow(Readyset::Query::CachedQuery).to receive(:all).and_return([build(:cached_query)])
            allow(Readyset).to receive(:create_cache!).with(id: cache_to_create.id)
            allow(STDIN).to receive(:gets).and_return("y\n")

            # Execute
            Rake::Task['readyset:caches:migrate'].execute

            # Verify
            expect(Readyset).to have_received(:create_cache!).with(id: cache_to_create.id)
          end

          it 'prints the expected output' do
            # Setup
            cache_to_create = build(:cached_query_2)
            generate_migration_file([build(:cached_query), cache_to_create])

            allow(Readyset::Query::CachedQuery).to receive(:all).and_return([build(:cached_query)])
            allow(Readyset).to receive(:create_cache!).with(id: cache_to_create.id)
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
            # Setup
            generate_migration_file([build(:cached_query)])

            cache_to_drop = build(:cached_query_2)
            allow(Readyset::Query::CachedQuery).to receive(:all).
              and_return([build(:cached_query), cache_to_drop])
            allow(Readyset).to receive(:drop_cache!).with(name_or_id: cache_to_drop.id)
            allow(STDIN).to receive(:gets).and_return("y\n")

            # Execute
            Rake::Task['readyset:caches:migrate'].execute

            # Verify
            expect(Readyset).to have_received(:drop_cache!).with(name_or_id: cache_to_drop.id)
          end

          it 'prints the expected output' do
            # Setup
            generate_migration_file([build(:cached_query)])

            cache_to_drop = build(:cached_query_2)
            allow(Readyset::Query::CachedQuery).to receive(:all).
              and_return([build(:cached_query), cache_to_drop])
            allow(Readyset).to receive(:drop_cache!).with(name_or_id: cache_to_drop.id)
            allow(STDIN).to receive(:gets).and_return("y\n")

            # Execute + Verify
            expected_message = "#{'Dropping'.red} 1 caches and #{'creating'.green} 0 caches. " \
              'Continue? (y/n) '
            expect { Rake::Task['readyset:caches:migrate'].execute }.to output(expected_message).
              to_stdout
          end
        end

        def generate_migration_file(caches)
          allow(Readyset::Query::CachedQuery).to receive(:all).and_return(caches)
          Rake::Task['readyset:caches:dump'].execute
          allow(Readyset::Query::CachedQuery).to receive(:all).and_call_original
        end
      end
    end
  end
end
