# lib/readyset.rb

require 'readyset/configuration'
require 'readyset/controller_extension'
require 'readyset/middleware'
require 'readyset/query'
require 'readyset/railtie' if defined?(Rails::Railtie)

require 'active_record'

module Readyset
  attr_writer :configuration

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.current_config
    configuration.inspect
  end

  # Executes a raw SQL query against Readyset. The query is sanitized prior to being executed.
  #
  # @param [Array<Object>] *sql_array the SQL array to be executed against ReadySet
  # @return [PG::Result]
  def self.raw_query(*sql_array)
    ActiveRecord::Base.establish_connection(Readyset::Configuration.configuration.database_url)
    ActiveRecord::Base.connection.execute(ActiveRecord::Base.sanitize_sql_array(sql_array))
  end
end
