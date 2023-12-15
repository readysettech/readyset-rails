# lib/readyset.rb

require 'readyset/configuration'
require 'readyset/controller_extension'
require 'readyset/query'
require 'readyset/railtie' if defined?(Rails::Railtie)
require 'readyset/relation_extension'

module Readyset
  attr_writer :configuration

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.current_configuration
    configuration.inspect
  end

  class << self
    alias_method :config, :configuration
    alias_method :current_config, :current_configuration
  end

  def self.configure
    yield configuration
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

    suffix = sql ? '%s' : '?'
    from = (id || sql)

    if always && name
      raw_query('CREATE CACHE ALWAYS ? FROM ' + suffix, name, from)
    elsif always
      raw_query('CREATE CACHE ALWAYS FROM ' + suffix, from)
    elsif name
      raw_query('CREATE CACHE ? FROM ' + suffix, name, from)
    else
      raw_query('CREATE CACHE FROM ' + suffix, from)
    end

    nil
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
      raw_query('DROP CACHE %s', sql)
    else
      raw_query('DROP CACHE ?', name_or_id)
    end

    nil
  end

  # Executes a raw SQL query against ReadySet. The query is sanitized prior to being executed.
  #
  # @param [Array<Object>] *sql_array the SQL array to be executed against ReadySet
  # @return [PG::Result]
  def self.raw_query(*sql_array) # :nodoc:
    ActiveRecord::Base.connected_to(role: reading_role, shard: shard, prevent_writes: false) do
      ActiveRecord::Base.connection.execute(ActiveRecord::Base.sanitize_sql_array(sql_array))
    end
  end

  # Routes to ReadySet any queries that occur in the given block. If `prevent_writes` is true, an
  # attempt to execute a write within the given block will raise an error. Keep in mind that if
  # `prevent_writes` is false, any writes that occur within the given block will be proxied through
  # ReadySet to the database.
  #
  # @param [Boolean] prevent_writes prevent writes from being executed on the connection to ReadySet
  # @yield a block whose queries should be routed to ReadySet
  # @return the value of the last line of the block
  def self.route(prevent_writes: true, &block)
    if prevent_writes
      ActiveRecord::Base.
        connected_to(role: reading_role, shard: shard, prevent_writes: true, &block)
    else
      ActiveRecord::Base.
        connected_to(role: writing_role, shard: shard, prevent_writes: false, &block)
    end
  end

  private

  class << self
    private(*delegate(:shard, to: :configuration))
  end

  def self.reading_role
    ActiveRecord.reading_role
  end
  private_class_method :reading_role

  def self.writing_role
    ActiveRecord.writing_role
  end
  private_class_method :writing_role
end
