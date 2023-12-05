module Readyset
  module RelationExtension
    extend ActiveSupport::Concern

    prepended do
      # Creates a new cache on ReadySet for this query. This method is a no-op if a cache for the
      # query already exists.
      #
      # @return [void]
      def create_readyset_cache!
        Readyset.create_cache!(sql: connection.to_sql(arel))
      end

      # Drops the cache on ReadySet associated with this query. This method is a no-op if a cache
      # for the query already doesn't exist.
      #
      # @return [void]
      def drop_readyset_cache!
        Readyset.drop_cache!(sql: connection.to_sql(arel))
      end
    end
  end
end
