require 'active_record'
require 'active_record/connection_adapters/abstract_adapter'
require 'active_record/connection_adapters/postgresql_adapter'
require 'readyset/error'

module ActiveRecord
  module ConnectionAdapters
    # The ReadySet adapter is a proxy object that delegates all its methods to an inner
    # PostgreSQLAdapter instance.
    class ReadysetAdapter
      ADAPTER_NAME = 'Readyset'.freeze

      # Finds the root cause of the given error and includes the Readyset::Error module in that
      # error's singleton class if the root cause was a `PG::Error`. This allows us to invoke
      # `#is_a?` on the error to determine if the error came from a connection to ReadySet.
      #
      # @param e [Exception] the error whose cause should be annotated
      # @return [void]
      def self.annotate_error(e)
        if e.cause
          annotate_error(e.cause)
        else
          if e.is_a?(::PG::Error)
            e.singleton_class.instance_eval do
              include ::Readyset::Error
            end
          end
        end

        nil
      end

      def self.method_missing(...)
        PostgreSQLAdapter.send(...)
      rescue => e
        annotate_error(e)
        raise e
      end

      def initialize(pg_conn)
        @inner = pg_conn
      end

      def method_missing(...)
        @inner.send(...)
      rescue => e
        self.class.annotate_error(e)
        raise e
      end
    end
  end
end
