require 'active_support/concern'

module Readyset
  class QueryAnnotator < ActiveSupport::CurrentAttributes
    attr_writer :routing_to_readyset

    def routing_to_readyset?
      !!@routing_to_readyset
    end
  end
end
