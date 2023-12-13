# frozen_string_literal: true

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

    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }
    let(:connection_url) { 'postgres://postgres:readyset@127.0.0.1:5432/test' }
    let(:query) { ['SELECT * FROM t WHERE x = ?', 0] }
    let(:results) { Object.new }
    let(:sanitized_query) { 'SELECT * FROM t WHERE x = 0' }

    before do
      Readyset::Configuration.configuration.database_url = connection_url

      allow(ActiveRecord::Base).to receive(:establish_connection).with(connection_url)
      allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
      allow(ActiveRecord::Base).to receive(:sanitize_sql_array).with(query).
        and_return(sanitized_query)
      allow(connection).to receive(:execute).with(sanitized_query).and_return(results)

      subject
    end

    it 'establishes a connection to ReadySet via the configured URL' do
      expect(ActiveRecord::Base).to have_received(:establish_connection).with(connection_url)
    end

    it 'sanitizes query input' do
      expect(ActiveRecord::Base).to have_received(:sanitize_sql_array).with(query)
    end

    it 'executes the query on the connection and returns the results' do
      expect(connection).to have_received(:execute).with(sanitized_query)
      is_expected.to eq(results)
    end
  end
end
