# frozen_string_literal: true

RSpec.describe ReadySet do
  it 'has a version number' do
    expect(ReadySet::VERSION).not_to be nil
  end

  describe '.raw_query' do
    subject { ReadySet.raw_query(*query) }

    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }
    let(:connection_url) { 'postgres://postgres:readyset@127.0.0.1:5432/test' }
    let(:query) { ['SELECT * FROM t WHERE x = ?', 0] }
    let(:results) { Object.new }
    let(:sanitized_query) { 'SELECT * FROM t WHERE x = 0' }

    before do
      ReadySet.configuration.connection_url = connection_url

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
