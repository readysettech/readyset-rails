RSpec.describe ActiveRecord::ReadysetConnectionHandling do
  class ConnectionHandler
    include ActiveRecord::ReadysetConnectionHandling
  end

  describe '#readyset_adapter_class' do
    subject { ConnectionHandler.new.readyset_adapter_class }

    it { should eq ActiveRecord::ConnectionAdapters::ReadysetAdapter }
  end

  describe '#readyset_connection' do
    context 'when the creation of the underlying Postgres connection raises an error' do
      context 'when the error is a PG::Error' do
        it 'annotates the singleton class of the root cause of the error with the ' \
            'Readyset::Error module' do
          handler = ConnectionHandler.new
          config = instance_double(Hash)
          allow(handler).to receive(:postgresql_connection).with(config).
            and_raise(PG::ConnectionBad)

          result = begin
                     handler.readyset_connection(config)
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
          handler = ConnectionHandler.new
          config = instance_double(Hash)
          allow(handler).to receive(:postgresql_connection).with(config).and_raise(StandardError)

          result = begin
            handler.readyset_connection(config)
                   rescue => e
                     e
          end

          expect(result).to be_a(StandardError)
          expect(result).not_to be_a(Readyset::Error)
        end
      end
    end

    context "when the creation of the underlying Postgres connection doesn't raise an error" do
      it 'creates a new Postgres connection and returns a Readyset connection that wraps it' do
        handler = ConnectionHandler.new
        config = instance_double(Hash)
        pg_conn = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        allow(handler).to receive(:postgresql_connection).with(config).and_return(pg_conn)

        result = handler.readyset_connection(config)

        expect(handler).to have_received(:postgresql_connection).with(config)
        expect(result).to be_a(ActiveRecord::ConnectionAdapters::ReadysetAdapter)
      end
    end
  end
end
