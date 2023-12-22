# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Readyset do
  it 'has a version number' do
    expect(Readyset::VERSION).not_to be nil
  end

  describe '.create_cache!' do
    let(:query) { build(:seen_but_not_cached_query) }

    context 'when given neither a SQL string nor an ID' do
      subject { Readyset.create_cache! }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when given both a SQL string and an ID' do
      subject { Readyset.create_cache!(sql: query.text, id: query.id) }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when given a SQL string but not an ID' do
      subject { Readyset.create_cache!(sql: query.text) }

      it_behaves_like 'a wrapper around a ReadySet SQL extension', 'CREATE CACHE FROM %s' do
        let(:args) { [query.text] }
      end
    end

    context 'when given an ID but not a SQL string' do
      subject { Readyset.create_cache!(id: query.id) }

      it_behaves_like 'a wrapper around a ReadySet SQL extension', 'CREATE CACHE FROM ?' do
        let(:args) { [query.id] }
      end
    end

    context 'when only the "always" parameter is passed' do
      subject { Readyset.create_cache!(id: query.id, always: true) }

      it_behaves_like 'a wrapper around a ReadySet SQL extension', 'CREATE CACHE ALWAYS FROM ?' do
        let(:args) { [query.id] }
      end
    end

    context 'when only the "name" parameter is passed' do
      subject { Readyset.create_cache!(id: query.id, name: name) }

      let(:name) { 'test cache' }

      it_behaves_like 'a wrapper around a ReadySet SQL extension', 'CREATE CACHE ? FROM ?' do
        let(:args) { [name, query.id] }
      end
    end

    context 'when both the "always" and "name" parameters are passed' do
      subject { Readyset.create_cache!(id: query.id, always: true, name: name) }

      let(:name) { 'test cache' }

      it_behaves_like 'a wrapper around a ReadySet SQL extension', 'CREATE CACHE ALWAYS ? FROM ?' do
        let(:args) { [name, query.id] }
      end
    end

    context 'when neither the "always" nor the "name" parameters are passed' do
      subject { Readyset.create_cache!(id: query.id) }

      it_behaves_like 'a wrapper around a ReadySet SQL extension', 'CREATE CACHE FROM ?' do
        let(:args) { [query.id] }
      end
    end
  end

  describe '.drop_cache!' do
    let(:query) { build(:seen_but_not_cached_query) }

    context 'when given neither a SQL string nor an ID' do
      subject { Readyset.drop_cache! }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when given both a SQL string and an ID' do
      subject { Readyset.drop_cache!(sql: query.text, name_or_id: query.id) }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when given a SQL string but not an ID' do
      subject { Readyset.drop_cache!(sql: query.text) }

      it_behaves_like 'a wrapper around a ReadySet SQL extension', 'DROP CACHE %s' do
        let(:args) { [query.text] }
      end
    end

    context 'when given an ID but not a SQL string' do
      subject { Readyset.drop_cache!(name_or_id: query.id) }

      it_behaves_like 'a wrapper around a ReadySet SQL extension', 'DROP CACHE ?' do
        let(:args) { [query.id] }
      end
    end
  end

  describe '.raw_query' do
    subject { Readyset.raw_query(*query) }

    let(:query) { ['SELECT * FROM cats WHERE name = ?', 'whiskers'] }

    before do
      ActiveRecord::Base.connected_to(shard: Readyset.configuration.shard) do
        Cat.create!(name: 'whiskers')
        Cat.create!(name: 'fluffy')
        Cat.create!(name: 'tails')
      end

      subject
    end

    it 'returns the results from the query' do
      expect(subject.size).to eq(1)
      expect(subject.first['name']).to eq('whiskers')
    end
  end

  describe '.route' do
    subject { Readyset.route(prevent_writes: prevent_writes, &block) }

    let(:query_results) { instance_double(Cat) }

    RSpec.shared_examples 'uses the expected connection parameters' do |role, shard|
      it "sets the role to be #{role}" do
        begin
          subject
        rescue ActiveRecord::ReadOnlyError
        end

        expect(@role).to eq(ActiveRecord.writing_role)
      end

      it "sets the shard to be #{shard}" do
        begin
          subject
        rescue ActiveRecord::ReadOnlyError
        end

        expect(@shard).to eq(Readyset.configuration.shard)
      end
    end

    context 'when prevent_writes is true' do
      let(:prevent_writes) { true }

      context 'when the block contains a write query' do
        let(:block) do
          Proc.new do
            @role = ActiveRecord::Base.connection.role
            @shard = ActiveRecord::Base.connection.shard
            Cat.create!(name: 'whiskers')
          end
        end

        it 'raises an ActiveRecord::ReadOnlyError' do
          expect { subject }.to raise_error(ActiveRecord::ReadOnlyError)
        end

        include_examples 'uses the expected connection parameters', ActiveRecord.writing_role,
          Readyset.configuration.shard
      end

      context 'when the block contains a read query' do
        let(:block) do
          Proc.new do
            @role = ActiveRecord::Base.connection.role
            @shard = ActiveRecord::Base.connection.shard
            'test return value'
          end
        end

        it 'returns the result of the block' do
          expect(subject).to eq('test return value')
        end

        include_examples 'uses the expected connection parameters', ActiveRecord.writing_role,
          Readyset.configuration.shard
      end
    end

    context 'when prevent_writes is false' do
      let(:prevent_writes) { false }

      context 'when the block contains a write query' do
        let(:block) do
          Proc.new do
            @role = ActiveRecord::Base.connection.role
            @shard = ActiveRecord::Base.connection.shard
            Cat.create!(name: 'whiskers')
            'test return value'
          end
        end

        it 'returns the result of the block' do
          expect(subject).to eq('test return value')
        end

        it 'executes the write against ReadySet' do
          subject

          exists = ActiveRecord::Base.connected_to(shard: Readyset.configuration.shard) do
            Cat.where(name: 'whiskers').exists?
          end

          expect(exists).to eq(true)

          exists = ActiveRecord::Base.connected_to(shard: :primary) do
            Cat.where(name: 'whiskers').exists?
          end

          expect(exists).to eq(false)
        end

        include_examples 'uses the expected connection parameters', ActiveRecord.writing_role,
          Readyset.configuration.shard
      end

      context 'when the block contains a read query' do
        let(:block) do
          Proc.new do
            @role = ActiveRecord::Base.connection.role
            @shard = ActiveRecord::Base.connection.shard
            Cat.where(name: 'whiskers').exists?
          end
        end

        before do
          ActiveRecord::Base.connected_to(shard: Readyset.configuration.shard) do
            Cat.create!(name: 'whiskers')
          end
        end

        it 'executes the read against ReadySet' do
          expect(subject).to eq(true)
        end

        include_examples 'uses the expected connection parameters', ActiveRecord.writing_role,
          Readyset.configuration.shard
      end
    end

    # NOTE: If query tags aren't available, it will annotate anything.
    # Adding a feature toggle via config would be redundant.
    context 'when query tags are available' do
      it 'annotates SQL queries with a "routed to ReadySet" tag' do
        # Setup - set up custom logger
        log = StringIO.new
        custom_logger = ActiveSupport::Logger.new(log)
        allow(ActiveRecord::Base).to receive(:logger).and_return(custom_logger)

        # Exercise - Run a query to be routed and tagged
        query = Cat.where(name: 'whiskers')
        Readyset.route { query }

        # Verify - Check if the query log contains the expected annotation
        log.rewind # To latest log.
        expect(log.read).to match(/routed_to_readyset\?[:=]true/)
      end

      # Only annotates ReadySet queries passing through .route
      context 'when routing queries' do
        it 'sets routing_to_readyset to true at the beginning of the method' do
          # Setup - Remember initial state
          starting_state = Readyset::QueryAnnotator.routing_to_readyset?

          # Exercise - Call the .route method and check the state within the block
          in_progress_state = nil
          Readyset.route { in_progress_state = Readyset::QueryAnnotator.routing_to_readyset? }

          # Verify - Check if routing_to_readyset was true inside the block
          expect(in_progress_state).to eq(true)

          # Teardown - Restore initial state
          Readyset::QueryAnnotator.routing_to_readyset = starting_state
        end

        # Without this, all queries in the Rails app
        # would be annotated as true.
        it 'sets routing_to_readyset to false at the end of the method' do
          # Setup - Remember initial state
          starting_state = Readyset::QueryAnnotator.routing_to_readyset?

          # Exercise - Call the .route method
          Readyset.route { Cat.where(name: 'whiskers') }

          # Verify - Check if routing_to_readyset was reset to false
          expect(Readyset::QueryAnnotator.routing_to_readyset?).to eq(false)

          # Teardown - Restore initial state
          Readyset::QueryAnnotator.routing_to_readyset = starting_state
        end
      end
      context 'when not using .route' do
        it 'flags #routed_to_readyset? as false' do
          # Setup - set up custom logger
          log = StringIO.new
          custom_logger = ActiveSupport::Logger.new(log)
          allow(ActiveRecord::Base).to receive(:logger).and_return(custom_logger)

          # Exercise - Run a query to be routed and tagged
          query = Cat.where(name: 'whiskers')

          ActiveRecord::Base.connection.execute(query.to_sql)
          # Verify - Check if the query log contains the expected annotation
          log.rewind # To latest log.
          expect(log.read).not_to match(/routed_to_readyset\?[:=]true/)
        end
      end
    end
  end
end
