# lib/readyset.rb

require 'active_record/connection_adapters/readyset_adapter'
require 'readyset/caches'
require 'readyset/configuration'
require 'readyset/controller_extension'
require 'readyset/health/healthchecker'
require 'readyset/model_extension'
require 'readyset/explain'
require 'readyset/query'
require 'readyset/query/cached_query'
require 'readyset/query/proxied_query'
require 'readyset/railtie' if defined?(Rails::Railtie)
require 'readyset/relation_extension'
require 'readyset/utils/window_counter'

# The Readyset module provides functionality to integrate ReadySet caching
# with Ruby on Rails applications.
# It offers methods to configure and manage ReadySet caches,
# as well as to route database queries through ReadySet.
module Readyset
  attr_writer :configuration

  # Retrieves the Readyset configuration, initializing it if it hasn't been set yet.
  # @return [Readyset::Configuration] the current configuration for Readyset.
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  # Creates a new cache on ReadySet using the given ReadySet query ID or SQL query. Exactly one of
  # the `id` or `sql` keyword arguments must be provided.
  #
  # This method is a no-op if a cache for the given ID/query already exists.
  #
  # @param [String] id the ReadySet query ID of the query from which a cache should be created
  # @param [String] sql the SQL string from which a cache should be created
  # @param [String] name the name for the cache being created
  # @param [Boolean] always whether the cache should always be used. if this is true, queries to
  # these caches will never fall back to the database
  # @return [void]
  # @raise [ArgumentError] raised if exactly one of the `id` or `sql` arguments was not provided
  def self.create_cache!(id: nil, sql: nil, name: nil, always: false)
    if (sql.nil? && id.nil?) || (!sql.nil? && !id.nil?)
      raise ArgumentError, 'Exactly one of the `id` and `sql` parameters must be provided'
    end

    query = 'CREATE CACHE '
    params = []

    if always
      query += 'ALWAYS '
    end

    unless name.nil?
      query += '? '
      params.push(name)
    end

    if sql
      query += 'FROM %s'
      params.push(sql)
    else
      query += 'FROM ?'
      params.push(id)
    end

    Readyset.raw_query(query, *params)

    nil
  end

  def self.current_config
    configuration.inspect
  end

  # Creates a new cache on ReadySet using the given SQL query or ReadySet query ID. Exactly one of
  # the `name_or_id` or `sql` keyword arguments must be provided.
  #
  # This method is a no-op if a cache for the given ID/query already doesn't exist.
  #
  # @param [String] name_or_id the name or the ReadySet query ID of the cache that should be dropped
  # @param [String] sql a SQL string for a query whose associated cache should be dropped
  # @return [void]
  # @raise [ArgumentError] raised if exactly one of the `name_or_id` or `sql` arguments was not
  # provided
  def self.drop_cache!(name_or_id: nil, sql: nil)
    if (sql.nil? && name_or_id.nil?) || (!sql.nil? && !name_or_id.nil?)
      raise ArgumentError, 'Exactly one of the `name_or_id` and `sql` parameters must be provided'
    end

    if sql
      Readyset.raw_query('DROP CACHE %s', sql)
    else
      Readyset.raw_query('DROP CACHE ?', name_or_id)
    end

    nil
  end

  # Executes a raw SQL query against ReadySet. The query is sanitized prior to being executed.
  #
  # @param [Array<Object>] *sql_array the SQL array to be executed against ReadySet
  # @return [PG::Result]
  def self.raw_query(*sql_array)
    ActiveRecord::Base.establish_connection(Readyset::Configuration.configuration.database_url)
    ActiveRecord::Base.connection.execute(ActiveRecord::Base.sanitize_sql_array(sql_array))
  end

  class << self
    alias_method :config, :configuration
  end

  # Configures Readyset by providing a block with configuration details.
  # @yieldparam [Readyset::Configuration] configuration the current configuration instance.
  # @yieldreturn [void]
  def self.configure
    yield configuration
  end

  # Creates a new cache on ReadySet using the given ReadySet query ID or SQL query.
  # @param id [String] the ReadySet query ID of the query from which a cache should be created.
  # @param sql [String] the SQL string from which a cache should be created.
  # @param name [String] the name for the cache being created.
  # @param always [Boolean] whether the cache should always be used;
  # queries to these caches will never fall back to the database if this is true.
  # @return [void]
  # @raise [ArgumentError] raised if exactly one of the `id` or `sql` arguments was not provided.
  def self.create_cache!(id: nil, sql: nil, name: nil, always: false)
    if (sql.nil? && id.nil?) || (!sql.nil? && !id.nil?)
      raise ArgumentError, 'Exactly one of the `id` and `sql` parameters must be provided'
    end

    connection = Readyset.route { ActiveRecord::Base.connection }
    from =
      if sql
        sql
      else
        connection.quote_column_name(id)
      end

    if always && name
      quoted_name = connection.quote_column_name(name)
      raw_query("CREATE CACHE ALWAYS #{quoted_name} FROM #{from}")
    elsif always
      raw_query("CREATE CACHE ALWAYS FROM #{from}")
    elsif name
      quoted_name = connection.quote_column_name(name)
      raw_query("CREATE CACHE #{quoted_name} FROM #{from}")
    else
      raw_query("CREATE CACHE FROM #{from}")
    end

    nil
  end

  # Drops an existing cache on ReadySet using the given query name.
  # @param name [String] the name of the cache that should be dropped.
  # @return [void]
  def self.drop_cache!(name)
    connection = Readyset.route { ActiveRecord::Base.connection }
    quoted_name = connection.quote_column_name(name)
    raw_query("DROP CACHE #{quoted_name}")

    nil
  end

  # Gets information about the given query from ReadySet, including whether it's supported to be
  # cached, its current status, the rewritten query text, and the query ID.
  #
  # The information about the given query is retrieved by invoking `EXPLAIN CREATE CACHE FROM` on
  # ReadySet.
  #
  # @param [String] a query about which information should be retrieved
  # @return [Explain]
  def self.explain(query)
    Explain.call(query)
  end

  # Executes a raw SQL query against ReadySet. The query is sanitized prior to being executed.
  # @note This method is not part of the public API.
  # @param sql_array [Array<Object>] the SQL array to be executed against ReadySet.
  # @return [PG::Result] the result of executing the SQL query.
  def self.raw_query_sanitize(*sql_array) # :nodoc:
    raw_query(ActiveRecord::Base.sanitize_sql_array(sql_array))
  end

  def self.raw_query(query) # :nodoc:
    ActiveRecord::Base.connected_to(role: writing_role, shard: shard, prevent_writes: false) do
      ActiveRecord::Base.connection.execute(query)
    end
  end

  # Routes to ReadySet any queries that occur in the given block.
  # @param prevent_writes [Boolean] if true, prevents writes from being executed on
  # the connection to ReadySet.
  # @yield a block whose queries should be routed to ReadySet.
  # @return the value of the last line of the block.
  def self.route(prevent_writes: true, &block)
    if healthchecker.healthy?
      begin
        if prevent_writes
          ActiveRecord::Base.connected_to(role: reading_role, shard: shard, prevent_writes: true,
            &block)
        else
          ActiveRecord::Base.connected_to(role: writing_role, shard: shard, prevent_writes: false,
            &block)
        end
      rescue => e
        healthchecker.process_exception(e)
        raise e
      end
    else
      yield
    end
  end

  private

  # Delegates the shard method to the configuration.
  class << self
    private(*delegate(:shard, to: :configuration))
  end

  def self.healthchecker
    @healthchecker ||= Readyset::Health::Healthchecker.new(
      config.failover,
      shard: shard,
    )
  end
  private_class_method :healthchecker

  # Returns the reading role for ActiveRecord connections.
  # @return [Symbol] the reading role.
  def self.reading_role
    ActiveRecord.reading_role
  end
  private_class_method :reading_role

  # Returns the writing role for ActiveRecord connections.
  # @return [Symbol] the writing role.
  def self.writing_role
    ActiveRecord.writing_role
  end
  private_class_method :writing_role
end
