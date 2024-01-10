require 'spec_helper'

require 'active_record/connection_adapters/postgresql_adapter'

RSpec.describe ActiveRecord::ConnectionAdapters::ReadysetAdapter do
  describe '.annotate_error' do
    context 'when the root cause of the error is a PG::Error' do
      it "includes the Readyset::Error module into the root cause's singleton class" do
        root_error = PG::Error.new
        error = build_error_with_root_cause(root_error)

        ActiveRecord::ConnectionAdapters::ReadysetAdapter.annotate_error(error)

        expect(root_error).to be_a(Readyset::Error)
      end
    end

    context 'when the root cause of the error is not a PG::Error' do
      it "does not include the Readyset::Error module into the root cause's singleton class" do
        root_error = StandardError.new
        error = build_error_with_root_cause(root_error)

        ActiveRecord::ConnectionAdapters::ReadysetAdapter.annotate_error(error)

        expect(root_error).not_to be_a(Readyset::Error)
      end
    end

    def build_error_with_root_cause(root_cause)
      begin
        begin
          raise root_cause
        rescue
          raise NoMethodError
        end
      rescue
        raise ArgumentError
      end
    rescue => e
      e
    end
  end

  describe '.method_missing' do
    it 'delegates class methods to PostgreSQLAdapter' do
      config = instance_double(Hash)
      allow(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).to receive(:database_exists?).
        with(config).and_return(true)

      result = ActiveRecord::ConnectionAdapters::ReadysetAdapter.database_exists?(config)

      expect(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).
        to have_received(:database_exists?).with(config)
      expect(result).to eq(true)
    end

    context 'when the method raises an error' do
      context 'when the error is a PG::Error' do
        it 'annotates the singleton class of the root cause of the error with the  ' \
            'Readyset::Error module' do
          config = instance_double(Hash)
          allow(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).to receive(:database_exists?).
            with(config).and_raise(PG::ConnectionBad)

          result = begin
            ActiveRecord::ConnectionAdapters::ReadysetAdapter.database_exists?(config)
                   rescue => e
                     e
          end

          expect(result).to be_a(PG::ConnectionBad)
          expect(result).to be_a(Readyset::Error)
        end
      end

      context 'when the error is not a PG::Error' do
        it 'does not annotate the singleton class of the root cause of the error with the' \
            'Readyset::Error module' do
          config = instance_double(Hash)
          allow(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).to receive(:database_exists?).
            with(config).and_raise(StandardError)

          result = begin
            ActiveRecord::ConnectionAdapters::ReadysetAdapter.database_exists?(config)
                   rescue => e
                     e
          end

          expect(result).to be_a(StandardError)
          expect(result).not_to be_a(Readyset::Error)
        end
      end
    end
  end

  describe '#method_missing' do
    it 'delegates instance methods to an inner PostgreSQLAdapter instance' do
      pg_adapter = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      readyset_adapter = ActiveRecord::ConnectionAdapters::ReadysetAdapter.new(pg_adapter)
      query = 'SELECT * FROM t WHERE x = 1'
      expected_result = instance_double(PG::Result)
      allow(pg_adapter).to receive(:exec_query).with(query).and_return(expected_result)

      result = readyset_adapter.exec_query(query)

      expect(pg_adapter).to have_received(:exec_query).with(query)
      expect(result).to eq(expected_result)
    end

    context 'when the method raises an error' do
      context 'when the error is a PG::Error' do
        it 'annotates the singleton class of the root cause of the error with the ' \
            'Readyset::Error module' do
          pg_adapter = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
          readyset_adapter = ActiveRecord::ConnectionAdapters::ReadysetAdapter.new(pg_adapter)
          query = 'SELECT * FROM t WHERE x = 1'
          allow(pg_adapter).to receive(:exec_query).with(query).and_raise(PG::ConnectionBad)

          result = begin
            readyset_adapter.exec_query(query)
                   rescue => e
                     e
          end

          expect(result).to be_a(PG::ConnectionBad)
          expect(result).to be_a(Readyset::Error)
        end
      end

      context 'when the error is not a PG::Error' do
        it 'does not annotate the singleton class of the root cause of the error with the' \
            'Readyset::Error module' do
          pg_adapter = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
          readyset_adapter = ActiveRecord::ConnectionAdapters::ReadysetAdapter.new(pg_adapter)
          query = 'SELECT * FROM t WHERE x = 1'
          allow(pg_adapter).to receive(:exec_query).with(query).and_raise(StandardError)

          result = begin
            readyset_adapter.exec_query(query)
                   rescue => e
                     e
          end

          expect(result).to be_a(StandardError)
          expect(result).not_to be_a(Readyset::Error)
        end
      end
    end
  end
end
