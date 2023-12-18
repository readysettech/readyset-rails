require 'active_support/concern'

module Readyset
  module QueryAnnotator
    extend ActiveSupport::Concern

    class_methods do
      def route(prevent_writes: true, &block)
        if Readyset.configuration.query_annotations
          ActiveSupport::ExecutionContext.set(readyset_query: 'routed_to_readyset')
          super
        else
          super
        end
      end
    end
  end
end
