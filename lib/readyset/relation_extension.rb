module Readyset
  module RelationExtension
    extend ActiveSupport::Concern

    prepended do
      # Creates a new cache on ReadySet for this query. This method is a no-op if a cache for the
      # query already exists.
      #
      # NOTE: If the ActiveRecord query eager loads associations (e.g. via `#includes`), the
      # the queries issued to do the eager loading will not have caches created. Those queries must
      # have their caches created separately.
      #
      # @return [void]
      def create_readyset_cache!
        Readyset.create_cache!(sql: to_sql)
      end

      # Drops the cache on ReadySet associated with this query. This method is a no-op if a cache
      # for the query already doesn't exist.
      #
      # NOTE: If the ActiveRecord query eager loads associations (e.g. via `#includes`), the
      # the queries issued to do the eager loading will not have caches dropped. Those queries must
      # have their caches dropped separately.
      #
      # @return [void]
      def drop_readyset_cache!
        Readyset.drop_cache!(sql: to_sql)
      end

      # Gets information about this query from ReadySet, including the query's ID, the normalized
      # query text, and whether the query is supported by ReadySet.
      #
      # @return [Readyset::Explain]
      def readyset_explain
        Readyset.explain(to_sql)
      end
    end
  end
end
