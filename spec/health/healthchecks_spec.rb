require 'spec_helper'

RSpec.describe Readyset::Health::Healthchecks do
  describe '#healthy?' do
    it 'reconnects the connection with every invocation' do
      healthchecks = Readyset::Health::Healthchecks.new(shard: :readyset)
      connection = stub_connection
      allow(connection).to receive(:reconnect!)
      allow(connection).to receive(:execute).with('SHOW READYSET STATUS').
        and_return([{ 'name' => 'Database Connection', 'value' => 'Connected' }])

      healthchecks.healthy?

      expect(connection).to have_received(:reconnect!)
    end

    context 'when an error is thrown in the context of the method' do
      it 'returns false' do
        healthchecks = Readyset::Health::Healthchecks.new(shard: :readyset)
        connection = stub_connection
        allow(connection).to receive(:reconnect!)
        allow(connection).to receive(:execute).with('SHOW READYSET STATUS').
          and_raise(StandardError)

        result = healthchecks.healthy?

        expect(result).to eq(false)
      end
    end

    context "when the status of ReadySet's database connection is something other than " \
        '"Connected"' do
      it 'returns false' do
        healthchecks = Readyset::Health::Healthchecks.new(shard: :readyset)
        connection = stub_connection
        allow(connection).to receive(:reconnect!)
        allow(connection).to receive(:execute).with('SHOW READYSET STATUS').
          and_return([{ 'name' => 'Database Connection', 'value' => 'Not Connected' }])

        result = healthchecks.healthy?

        expect(result).to eq(false)
      end
    end

    context "when the status of ReadySet's database connection is \"Connected\"" do
      it 'returns true' do
        healthchecks = Readyset::Health::Healthchecks.new(shard: :readyset)
        connection = stub_connection
        allow(connection).to receive(:reconnect!)
        allow(connection).to receive(:execute).with('SHOW READYSET STATUS').
          and_return([{ 'name' => 'Database Connection', 'value' => 'Connected' }])

        result = healthchecks.healthy?

        expect(result).to eq(true)
      end
    end

    def stub_connection
      pg_conn = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      conn = ActiveRecord::ConnectionAdapters::ReadysetAdapter.new(pg_conn)
      allow(ActiveRecord::Base).to receive(:connected_to).with(shard: :readyset).and_yield
      allow(ActiveRecord::Base).to receive(:retrieve_connection).and_return(conn)

      conn
    end
  end
end
