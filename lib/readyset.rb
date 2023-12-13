# lib/readyset.rb

require 'readyset/configuration'
require 'readyset/controller_extension'
require 'readyset/query'
require 'readyset/railtie' if defined?(Rails::Railtie)
require 'readyset/relation_extension'

require 'active_record'

module Readyset
  attr_writer :configuration

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

    suffix = sql ? '%s' : '?'
    from = (id || sql)

    if always && name
      Readyset.raw_query('CREATE CACHE ALWAYS ? FROM ' + suffix, name, from)
    elsif always
      Readyset.raw_query('CREATE CACHE ALWAYS FROM ' + suffix, from)
    elsif name
      Readyset.raw_query('CREATE CACHE ? FROM ' + suffix, name, from)
    else
      Readyset.raw_query('CREATE CACHE FROM ' + suffix, from)
    end

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
end
