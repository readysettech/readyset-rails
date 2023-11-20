# lib/ready_set/connection.rb

require 'active_record'

module ReadySet
  class Connection
    class NotReadyError < StandardError; end

    def self.establish
      ActiveRecord::Base.establish_connection(ReadySet.configuration.connection_url)
      check_database_status
      ActiveRecord::Base.connection
    end

    def self.check_database_status
      status_response = ActiveRecord::Base.connection.execute('SHOW READYSET STATUS;').first
      status = status_response && status_response['value']

      unless status&.match(/Completed/)
        raise NotReadyError, 'ReadySet database is not ready for service!'
      end
    end
  end
end
