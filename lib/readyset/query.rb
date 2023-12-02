# lib/readyset/query.rb

require 'active_model'

module Readyset
  # Represents a query that has been seen by ReadySet. This query may be cached or uncached.
  class Query
    include ActiveModel::AttributeMethods

    class BaseError < StandardError
      attr_reader :id

      def initialize(id)
        @id = id
      end
    end

    # An error raise when a query is expected not to be cached but is.
    class CacheAlreadyExistsError < BaseError
      def to_s
        "Query #{id} already has a cache"
      end
    end

    # An error raised when a `Readyset::Query` is expected to be cached but isn't.
    class NotCachedError < BaseError
      def to_s
        "Query #{id} is not cached"
      end
    end

    # An error raised when a `Readyset::Query` with the given ID can't be found on the ReadySet
    # instance.
    class NotFoundError < BaseError
      def to_s
        "Query not found for ID #{id}"
      end
    end

    # An error raised when a `Readyset::Query` is expected to be supported but isn't.
    class UnsupportedError < BaseError
      def to_s
        "Query #{id} is unsupported"
      end
    end

    attr_reader :id, :text, :cache_name, :supported, :count

    # Returns all of the queries currently cached on ReadySet by invoking the `SHOW CACHES` SQL
    # extension on ReadySet.
    #
    # @return [Array<Readyset::Query>]
    def self.all_cached
      Readyset.raw_query('SHOW CACHES').map { |result| new(result) }
    end

    # Returns all of the queries seen by ReadySet that are not currently cached. This list is
    # retrieved by invoking the `SHOW PROXIED QUERIES` SQL extension on ReadySet.
    #
    # @return [Array<Readyset::Query>]
    def self.all_seen_but_not_cached
      Readyset.raw_query('SHOW PROXIED QUERIES').map { |result| new(result) }
    end

    # Creates a cache for every supported query seen by ReadySet that is not already cached.
    #
    # @param [Boolean] always whether the cache should always be used. if this is true, queries
    # to these caches will never fall back to the database
    # @return [void]
    def self.cache_all_supported!(always: false)
      all_seen_but_not_cached.
        select { |query| query.supported == :yes }.
        each { |query| query.cache!(always: always) }

      nil
    end

    # Drops all the caches that exist on ReadySet.
    #
    # @return [void]
    def self.drop_all_caches!
      Readyset.raw_query('DROP ALL CACHES')

      nil
    end

    # Finds the query with the given query ID by directly querying ReadySet. If a query with the
    # given ID doesn't exist, this method raises a `Readyset::Query::NotFoundError`.
    #
    # @param [String] id the ID of the query to be searched for
    # @return [Query]
    # @raise [Readyset::Query::NotFoundError] raised if a query with the given ID cannot be found
    def self.find(id)
      find_seen_but_not_cached(id)
    rescue NotFoundError
      find_cached(id)
    end

    # Returns the cached query with the given query ID by directly querying ReadySet. If a cached
    # query with the given ID doesn't exist, this method raises a `Readyset::Query::NotFoundError`.
    #
    # @param [String] id the ID of the query to be searched for
    # @return [Query]
    # @raise [Readyset::Query::NotFoundError] raised if a cached query with the given ID cannot be
    # found
    def self.find_cached(id)
      find_inner('SHOW CACHES WHERE query_id = ?', id)
    end

    # Returns the query with the given query ID that has been seen by ReadySet but is not cached.
    # The query is searched for by directly querying ReadySet. If a seen-but-not-cached query with
    # the given ID doesn't exist, this method raises a `Readyset::Query::NotFoundError`.
    #
    # @param [String] id the ID of the query to be searched for
    # @return [Query]
    # @raise [Readyset::Query::NotFoundError] raised if a seen-but-not-cached query with the given
    # ID cannot be found
    def self.find_seen_but_not_cached(id)
      find_inner('SHOW PROXIED QUERIES WHERE query_id = ?', id)
    end

    # Constructs a new `Readyset::Query` from the given hash. The keys of this hash should
    # correspond to the columns in the results returned by the `SHOW PROXIED QUERIES` and
    # `SHOW CACHES` ReadySet SQL extensions.
    #
    # @param [Hash] attributes the attributes from which the `Readyset::Query` should be
    # constructed
    # @return [Query]
    def initialize(attributes)
      @id = attributes[:'query id']
      @text = attributes[:'proxied query'] || attributes[:'query text']
      @supported = (attributes[:'readyset supported'] || 'yes').to_sym
      @cache_name = attributes[:'cache name']
      @fallback_behavior = attributes[:'fallback behavior']&.to_sym
      @count = attributes[:count]
    end

    # Checks two queries for equality by comparing all of their attributes.
    #
    # @param [Query] the query against which `self` should be compared
    # @return [Boolean]
    def ==(other)
      id == other.id &&
        text == other.text &&
        supported == other.supported &&
        cache_name == other.cache_name &&
        fallback_behavior == other.fallback_behavior &&
        count == other.count
    end

    # Creates a cache on ReadySet for this query.
    #
    # @param [String] name the name for the cache being created
    # @param [Boolean] always whether the cache should always be used. if this is true, queries
    # to these caches will never fall back to the database
    # @return [void]
    # @raise [Readyset::Query::CacheAlreadyExistsError] raised if this method is invoked on a
    # query that already has a cache
    # @raise [Readyset::Query::UnsupportedError] raised if this method is invoked on an
    # unsupported query
    def cache!(name: nil, always: false)
      if cached?
        raise CacheAlreadyExistsError, id
      elsif supported == :unsupported
        raise UnsupportedError, id
      else
        query = 'CREATE CACHE '
        params = []

        if always
          query += 'ALWAYS '
        end

        unless name.nil?
          query += '? '
          params.push(name)
        end

        query += 'FROM %s'
        params.push(id)

        Readyset.raw_query(query, *params)

        reload
      end
    end

    # Returns true if the query is cached and false otherwise.
    #
    # @return [Boolean]
    def cached?
      !!@cache_name
    end

    # Drops the cache associated with this query.
    #
    # @return [void]
    # @raise [Readyset::Query::NotCachedError] raised if this method is invoked on a query that
    # doesn't have a cache
    def drop_cache!
      if cached?
        Readyset.raw_query('DROP CACHE %s', id)
        reload
      else
        raise NotCachedError, id
      end
    end

    # Returns true if the cached query supports falling back to the upstream database and false
    # otherwise. If the query is not cached, this method raises a
    # `Readyset::Query::NotCachedError`.
    #
    # @return [Boolean]
    # @raise [Readyset::Query::NotCachedError]
    def fallback_allowed?
      if cached?
        @fallback_behavior == 'fallback allowed'.to_sym
      else
        raise NotCachedError, id
      end
    end

    # Reloads the informtion for this query by getting the latest information directly from
    # ReadySet. This method mutates its receiver.
    #
    # @return [void]
    def reload
      reloaded = Query.find(id)

      @text = reloaded.text
      @supported = reloaded.supported
      @cache_name = reloaded.cache_name
      @fallback_behavior = reloaded.fallback_behavior
      @count = reloaded.count

      nil
    end

    protected

    attr_reader :fallback_behavior

    private

    def self.find_inner(query, id)
      result = Readyset.raw_query(query, id).first

      if result.nil?
        raise NotFoundError, id
      else
        new(result.to_h.symbolize_keys)
      end
    end
    private_class_method :find_inner
  end
end
