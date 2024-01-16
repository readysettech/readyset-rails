require 'active_model'

module Readyset
  # Represents a table from the database as it is known by ReadySet.
  class Table
    include ActiveModel::AttributeMethods

    # An error raised when a table is expected to be replicated but isn't.
    class NotReplicatedError < StandardError
      attr_reader :description, :name

      def initialize(name, description)
        @name = name
        @description = description
      end

      def to_s
        "Table #{name} is not replicated: #{description}"
      end
    end

    attr_reader :description, :name, :status

    # Returns a list of all the tables known by ReadySet along with their statuses. This
    # information is retrieved by invoking `SHOW READYSET TABLES` on ReadySet.
    #
    # @return [Array<ReadySet::Table>]
    def self.all
      Readyset.raw_query('SHOW READYSET TABLES').map do |result|
        from_readyset_result(**result.to_h.symbolize_keys)
      end
    end

    def initialize(name:, status:, description:) # :nodoc:
      @name = name
      @status = status
      @description = description
    end

    # Compares two Readyset::Tables attribute-wise, returning true only if all the attributes
    # match across `self` and `other`.
    #
    # @param other [Readyset::Table] the table to which `self` should be compared
    # @return [Boolean]
    def ==(other) # :nodoc:
      self.name == other.name &&
        self.description == other.description &&
        self.status == other.status
    end

    private

    def self.from_readyset_result(**attributes)
      new(
        name: attributes[:table],
        status: attributes[:status].downcase.gsub(' ', '_').to_sym,
        description: attributes[:description]
      )
    end
    private_class_method :from_readyset_result
  end
end
