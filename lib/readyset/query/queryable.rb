module Readyset
  module Query
    module Queryable
      private

      def all(query) # :nodoc:
        Readyset.raw_query(query).map do |result|
          from_readyset_result(**result.symbolize_keys)
        end
      end

      def find(query, id) # :nodoc:
        result = Readyset.raw_query_sanitize(query, id).first

        if result.nil?
          raise NotFoundError, id
        else
          from_readyset_result(**result.to_h.symbolize_keys)
        end
      end
    end
  end
end
