# lib/readyset.rb

require 'readyset/configuration'
require 'readyset/controller_extension'
require 'readyset/model_extension'
require 'readyset/query'
require 'readyset/query/cached_query'
require 'readyset/query/proxied_query'
require 'readyset/railtie' if defined?(Rails::Railtie)
require 'readyset/relation_extension'

# The Readyset module provides functionality to integrate ReadySet caching
# with Ruby on Rails applications.
# It offers methods to configure and manage ReadySet caches,
# as well as to route database queries through ReadySet.
module Readyset
  # Sets the configuration for Readyset.
  # @!attribute [w] configuration
  attr_writer :configuration

  # Retrieves the Readyset configuration, initializing it if it hasn't been set yet.
  # @return [Readyset::Configuration] the current configuration for Readyset.
  def self.configuration
    @configuration ||= Configuration.new
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
  # @param id_or_sql [String] the query ID or SQL string from which a cache should be created.
  # @param name [String] the name for the cache being created.
  # @param always [Boolean] whether the cache should always be used;
  # queries to these caches will never fall back to the database if this is true.
  # @return [void]
  def self.create_cache!(id_or_sql, name: nil, always: false)
    if always && name
      raw_query('CREATE CACHE ALWAYS %s FROM %s', name, id_or_sql)
    elsif always
      raw_query('CREATE CACHE ALWAYS FROM %s', id_or_sql)
    elsif name
      raw_query('CREATE CACHE %s FROM %s', name, id_or_sql)
    else
      raw_query('CREATE CACHE FROM %s', id_or_sql)
    end

    nil
  end

  # Drops an existing cache on ReadySet.
  # @param query_identifier [String] the name of the cache that should be dropped
  # @return [void]
  def self.drop_cache!(query_identifier)
    raw_query('DROP CACHE %s', query_identifier)

    nil
  end

  # Executes a raw SQL query against ReadySet. The query is sanitized prior to being executed.
  # @note This method is not part of the public API.
  # @param sql_array [Array<Object>] the SQL array to be executed against ReadySet.
  # @return [PG::Result] the result of executing the SQL query.
  def self.raw_query(*sql_array) # :nodoc:
    ActiveRecord::Base.connected_to(role: reading_role, shard: shard, prevent_writes: false) do
      ActiveRecord::Base.connection.execute(ActiveRecord::Base.sanitize_sql_array(sql_array))
    end
  end

  # Routes to ReadySet any queries that occur in the given block.
  # @param prevent_writes [Boolean] if true, prevents writes from being executed on
  # the connection to ReadySet.
  # @yield a block whose queries should be routed to ReadySet.
  # @return the value of the last line of the block.
  def self.route(prevent_writes: true, &block)
    if prevent_writes
      ActiveRecord::Base.connected_to(role: reading_role, shard: shard, prevent_writes: true,
        &block)
    else
      ActiveRecord::Base.connected_to(role: writing_role, shard: shard, prevent_writes: false,
        &block)
    end
  end

  private

  # Delegates the shard method to the configuration.
  class << self
    private(*delegate(:shard, to: :configuration))
  end

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
