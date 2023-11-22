# lib/ready_set/query.rb

require 'active_model'

module ReadySet
  # Represents a query that has been seen by ReadySet. This query may be cached or uncached.
  class Query
    include ActiveModel::AttributeMethods

    # An error raised when a `ReadySet::Query` is expected to be cached but isn't.
    class NotCachedError < StandardError
      attr_reader :id

      def initialize(id)
        @id = id
      end

      def to_s
        "Query #{id} is not cached"
      end
    end

    # An error raised when a `ReadySet::Query` with the given ID can't be found on the ReadySet
    # instance.
    class NotFoundError < StandardError
      attr_reader :id

      def initialize(id)
        @id = id
      end

      def to_s
        "Query not found for ID #{id}"
      end
    end

    attr_reader :id, :text, :cache_name, :supported, :count

    # Returns all of the queries currently cached on ReadySet by invoking the `SHOW CACHES` SQL
    # extension on ReadySet.
    #
    # @return [Array<ReadySet::Query>]
    def self.all_cached
      ReadySet.raw_query('SHOW CACHES').map { |result| new(result) }
    end

    # Returns all of the queries seen by ReadySet that are not currently cached. This list is
    # retrieved by invoking the `SHOW PROXIED QUERIES` SQL extension on ReadySet.
    #
    # @return [Array<ReadySet::Query>]
    def self.all_seen_but_not_cached
      ReadySet.raw_query('SHOW PROXIED QUERIES').map { |result| new(result) }
    end

    # Finds the query with the given query ID by directly querying ReadySet. If a query with the
    # given ID doesn't exist, this method raises a `ReadySet::Query::NotFoundError`.
    #
    # @param [String] id the ID of the query to be searched for
    # @return [Query]
    # @raise [ReadySet::Query::NotFoundError] raised if a query with the given ID cannot be found
    def self.find(id)
      find_seen_but_not_cached(id)
    rescue NotFoundError
      find_cached(id)
    end

    # Returns the cached query with the given query ID by directly querying ReadySet. If a cached
    # query with the given ID doesn't exist, this method raises a `ReadySet::Query::NotFoundError`.
    #
    # @param [String] id the ID of the query to be searched for
    # @return [Query]
    # @raise [ReadySet::Query::NotFoundError] raised if a cached query with the given ID cannot be
    # found
    def self.find_cached(id)
      find_inner('SHOW CACHES WHERE query_id = ?', id)
    end

    # Returns the query with the given query ID that has been seen by ReadySet but is not cached.
    # The query is searched for by directly querying ReadySet. If a seen-but-not-cached query with
    # the given ID doesn't exist, this method raises a `ReadySet::Query::NotFoundError`.
    #
    # @param [String] id the ID of the query to be searched for
    # @return [Query]
    # @raise [ReadySet::Query::NotFoundError] raised if a seen-but-not-cached query with the given
    # ID cannot be found
    def self.find_seen_but_not_cached(id)
      find_inner('SHOW PROXIED QUERIES WHERE query_id = ?', id)
    end

    # Constructs a new `ReadySet::Query` from the given hash. The keys of this hash should
    # correspond to the columns in the results returned by the `SHOW PROXIED QUERIES` and
    # `SHOW CACHES` ReadySet SQL extensions.
    #
    # @param [Hash] attributes the attributes from which the `ReadySet::Query` should be
    # constructed
    # @return [Query]
    def initialize(attributes)
      @id = attributes['query id']
      @text = attributes['proxied query'] || attributes['query text']
      @supported = (attributes['readyset supported'] || 'yes').to_sym
      @cache_name = attributes['cache name']
      @fallback_behavior = attributes['fallback behavior']&.to_sym
      @count = attributes['count']
    end

    # Returns true if the query is cached and false otherwise.
    #
    # @return [Boolean]
    def cached?
      !!@cache_name
    end

    # Returns true if the cached query supports falling back to the upstream database and false
    # otherwise. If the query is not cached, this method raises a
    # `ReadySet::Query::NotCachedError`.
    #
    # @return [Boolean]
    # @raise [ReadySet::Query::NotCachedError]
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
      result = ReadySet.raw_query(query, id).first

      if result.nil?
        raise NotFoundError, id
      else
        new(result.to_h)
      end
    end
    private_class_method :find_inner
  end
end
