require 'active_model'

module Readyset
  # Represents ReadySet's current status.
  class Status
    include ActiveModel::AttributeMethods

    attr_reader :connection_count, :controller_status, :database_connection_status,
      :last_completed_snapshot, :last_replicator_error, :last_started_controller,
      :last_started_replication, :minimum_replication_offset, :maximum_replication_offset,
      :snapshot_status

    # Returns a list of all the tables known by ReadySet along with their statuses. This
    # information is retrieved by invoking `SHOW READYSET STATUS` on ReadySet.
    #
    # @return [Array<ReadySet::Table>]
    def self.call
      from_readyset_result(Readyset.raw_query('SHOW READYSET STATUS'))
    end

    def initialize(connection_count:, controller_status:, database_connection_status:,
                   last_completed_snapshot:, last_replicator_error:, last_started_controller:,
                   last_started_replication:, minimum_replication_offset:,
                   maximum_replication_offset:, snapshot_status:) # :nodoc:
      @connection_count = connection_count
      @database_connection_status = database_connection_status
      @last_completed_snapshot = last_completed_snapshot
      @last_replicator_error = last_replicator_error
      @last_started_controller = last_started_controller
      @last_started_replication = last_started_replication
      @minimum_replication_offset = minimum_replication_offset
      @maximum_replication_offset = maximum_replication_offset
      @controller_status = controller_status
      @snapshot_status = snapshot_status
    end

    private

    def self.from_readyset_result(rows)
      attributes = rows.each_with_object({}) { |row, acc| acc[row['name']] = row['value'] }

      new(
        connection_count: attributes['Connection Count'].to_i,
        database_connection_status:
          attributes['Database Connection'].downcase.gsub(' ', '_').to_sym,
        last_completed_snapshot: parse_timestamp_if_not_nil(attributes['Last completed snapshot']),
        last_replicator_error: attributes['Last replicator error'],
        last_started_controller: parse_timestamp_if_not_nil(attributes['Last started Controller']),
        last_started_replication:
          parse_timestamp_if_not_nil(attributes['Last started replication']),
        minimum_replication_offset: attributes['Minimum Replication Offset'],
        maximum_replication_offset: attributes['Maximum Replication Offset'],
        controller_status: attributes['ReadySet Controller Status'],
        snapshot_status: attributes['Snapshot Status'].downcase.gsub(' ', '_').to_sym,
      )
    end
    private_class_method :from_readyset_result

    def self.parse_timestamp_if_not_nil(timestamp)
      unless timestamp.nil?
        Time.parse(timestamp)
      end
    end
    private_class_method :parse_timestamp_if_not_nil
  end
end
