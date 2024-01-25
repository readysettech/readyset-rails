# frozen_string_literal: true

module ActiveRecord
  # The methods in these modules are required for Rails to recognize our custom adapter
  module ReadysetConnectionHandling
    def readyset_adapter_class
      ConnectionAdapters::ReadysetAdapter
    end

    def readyset_connection(config) # :nodoc:
      pg_conn = postgresql_connection(config)
      readyset_adapter_class.new(pg_conn)
    rescue => e
      readyset_adapter_class.annotate_error(e)
      raise e
    end
  end
end
