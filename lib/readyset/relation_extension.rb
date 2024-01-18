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
      # @param always [Boolean] whether the queries to this cache should always be served by
      #                         ReadySet, preventing fallback to the uptream database
      # @return [void]
      def create_readyset_cache!(always: false)
        Readyset.create_cache!(to_sql, always: always)
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
