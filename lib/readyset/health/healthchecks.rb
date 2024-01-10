module Readyset
  module Health
    # Represents healthchecks that are run against ReadySet to determine whether ReadySet is in a
    # state where it can serve queries.
    class Healthchecks
      def initialize(shard:)
        @shard = shard
      end

      # Checks if ReadySet is healthy by invoking `SHOW READYSET STATUS` and checking if
      # ReadySet is connected to the upstream database.
      #
      # @return [Boolean] whether ReadySet is healthy
      def healthy?
        connection.execute('SHOW READYSET STATUS').any? do |row|
          row['name'] == 'Database Connection' && row['value'] == 'Connected'
        end
      rescue
        false
      end

      private

      attr_reader :shard

      def connection
        @connection ||= ActiveRecord::Base.connected_to(shard: shard) do
          ActiveRecord::Base.retrieve_connection
        end

        # We reconnect with each healthcheck to ensure that connection state is not cached across
        # uses
        @connection.reconnect!

        @connection
      rescue
        false
      end
    end
  end
end
