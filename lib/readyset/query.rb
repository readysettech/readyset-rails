# lib/readyset/query.rb

require 'active_model'

module Readyset
  module Query
    class BaseError < StandardError
      attr_reader :id

      def initialize(id)
        @id = id
      end
    end

    # An error raised when a query with the given ID can't be found on the ReadySet
    # instance.
    class NotFoundError < BaseError
      def to_s
        "Query not found for ID #{id}"
      end
    end
  end
end
