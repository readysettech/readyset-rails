require 'active_model'

require 'readyset/query/queryable'

module Readyset
  module Query
    # Represents a query that is cached by ReadySet.
    class CachedQuery
      include ActiveModel::AttributeMethods
      extend Queryable

      attr_reader :id, :text, :name, :count, :always

      # Returns all of the queries currently cached on ReadySet by invoking the `SHOW CACHES` SQL
      # extension on ReadySet.
      #
      # @return [Array<CachedQuery>]
      def self.all
        super('SHOW CACHES')
      end

      # Drops all the caches that exist on ReadySet.
      #
      # @return [void]
      def self.drop_all!
        Readyset.raw_query('DROP ALL CACHES')

        nil
      end

      # Returns the cached query with the given query ID by directly querying ReadySet. If a cached
      # query with the given ID doesn't exist, this method raises a
      # `Readyset::Query::NotFoundError`.
      #
      # @param [String] id the ID of the query to be searched for
      # @return [CachedQuery]
      # @raise [Readyset::Query::NotFoundError] raised if a cached query with the given ID cannot be
      # found
      def self.find(id)
        super('SHOW CACHES WHERE query_id = ?', id)
      end

      # Constructs a new `CachedQuery` from the given attributes.
      #
      # @param [Hash] attributes the attributes from which the `CachedQuery` should be
      # constructed
      # @return [CachedQuery]
      def initialize(id:, text:, name:, always:, count:)
        @id = id
        @text = text
        @name = name
        @always = always
        @count = count
      end

      # Checks two queries for equality by comparing all of their attributes.
      #
      # @param [CachedQuery] the query against which `self` should be compared
      # @return [Boolean]
      def ==(other)
        id == other.id &&
          text == other.text &&
          name == other.name &&
          always == other.always &&
          count == other.count
      end

      # Returns false if the cached query supports falling back to the upstream database and true
      # otherwise.
      #
      # @return [Boolean]
      def always?
        always
      end

      # Drops the cache associated with this query.
      #
      # @return [void]
      def drop!
        Readyset.drop_cache!(name_or_id: id)
        ProxiedQuery.find(id: id)
      end

      private

      # Constructs a new `CachedQuery` from the given attributes. The attributes accepted
      # by this method of this hash should correspond to the columns in the results returned by the
      # `SHOW CACHES` ReadySet SQL extension.
      #
      # @param [Hash] attributes the attributes from which the `CachedQuery` should be
      # constructed
      # @return [CachedQuery]
      def self.from_readyset_result(**attributes)
        new(
          id: attributes[:'query id'],
          text: attributes[:'query text'],
          name: attributes[:'cache name'],
          always: attributes[:'fallback behavior'] != 'fallback allowed',
          count: attributes[:count].to_i,
        )
      end
      private_class_method :from_readyset_result
    end
  end
end
