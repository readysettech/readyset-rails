# lib/readyset/connection.rb

require "active_record"

module Readyset
  class Connection
    class NotReadyError < StandardError; end

    def self.establish
      ActiveRecord::Base.establish_connection(Readyset.configuration.connection_url)
      check_database_status
      ActiveRecord::Base.connection
    end

    def self.check_database_status
      status_response = ActiveRecord::Base.connection.execute("SHOW READYSET STATUS;").first
      status = status_response && status_response["value"]

      raise NotReadyError, "Readyset database is not ready for service!" unless status && status.match(/Completed/)
    end
  end
end
