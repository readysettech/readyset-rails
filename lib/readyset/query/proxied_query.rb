require 'active_model'

require 'readyset/query'
require 'readyset/query/queryable'

module Readyset
  module Query
    # Represents an uncached query that has been proxied by ReadySet.
    class ProxiedQuery
      include ActiveModel::AttributeMethods
      extend Queryable

      # An error raised when a `ProxiedQuery` is expected to be supported but isn't.
      class UnsupportedError < Query::BaseError
        def to_s
          "Query #{id} is unsupported"
        end
      end

      attr_reader :id, :text, :supported, :count

      # Returns all of the queries proxied by ReadySet that are not currently cached. This list is
      # retrieved by invoking the `SHOW PROXIED QUERIES` SQL extension on ReadySet.
      #
      # @return [Array<ProxiedQuery>]
      def self.all
        super('SHOW PROXIED QUERIES')
      end

      # Creates a cache for every proxied query that is not already cached.
      #
      # @param [Boolean] always whether the cache should always be used. if this is true, queries
      # to these caches will never fall back to the database
      # @return [Array<CachedQuery>] an array of the newly-created caches
      def self.cache_all_supported!(always: false)
        all.
          select { |query| query.supported == :yes }.
          map { |query| query.cache!(always: always) }
      end

      # Clears the list of proxied queries on ReadySet.
      def self.drop_all!
        Readyset.raw_query('DROP ALL PROXIED QUERIES')
      end

      # Returns the proxied query with the given query ID. The query is searched for by directly
      # querying ReadySet. If a proxied query with the given ID doesn't exist, this method raises a
      # `Readyset::Query::NotFoundError`.
      #
      # @param [String] id the ID of the query to be searched for
      # @return [ProxiedQuery]
      # @raise [Readyset::Query::NotFoundError] raised if a proxied query with the given
      # ID cannot be found
      def self.find(id)
        super('SHOW PROXIED QUERIES WHERE query_id = ?', id)
      end

      # Constructs a new `ProxiedQuery` from the given attributes.
      #
      # @param [Hash] attributes the attributes from which the `ProxiedQuery` should be
      # constructed
      # @return [ProxiedQuery]
      def initialize(id:, text:, supported:, count:)
        @id = id
        @text = text
        @supported = supported
        @count = count
      end

      # Checks two proxied queries for equality by comparing all of their attributes.
      #
      # @param [ProxiedQuery] the query against which `self` should be compared
      # @return [Boolean]
      def ==(other)
        id == other.id &&
          text == other.text &&
          supported == other.supported
      end

      # Creates a cache on ReadySet for this query.
      #
      # @param [String] name the name for the cache being created
      # @param [Boolean] always whether the cache should always be used. if this is true, queries
      # to these caches will never fall back to the database
      # @return [CachedQuery] the newly-cached query
      # @raise [ProxiedQuery::UnsupportedError] raised if this method is invoked on an
      # unsupported query
      def cache!(name: nil, always: false)
        if supported == :unsupported
          raise UnsupportedError, id
        else
          Readyset.create_cache!(id: id, name: name, always: always)
          CachedQuery.find(id)
        end
      end

      private

      # Constructs a new `ProxiedQuery` from the given attributes. The attributes accepted
      # by this method of this hash should correspond to the columns in the results returned by the
      # `SHOW PROXIED QUERIES` ReadySet SQL extension.
      #
      # @param [Hash] attributes the attributes from which the `ProxiedQuery` should be constructed
      # @return [ProxiedQuery]
      def self.from_readyset_result(**attributes)
        new(
          id: attributes[:'query id'],
          text: attributes[:'proxied query'],
          supported: attributes[:'readyset supported'].to_sym,
          count: attributes[:count].to_i,
        )
      end
      private_class_method :from_readyset_result
    end
  end
end
