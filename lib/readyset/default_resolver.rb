# lib/readyset/default_resolver.rb

require 'active_record'

module Readyset
  class DefaultResolver < ActiveRecord::Middleware::DatabaseSelector::Resolver
    def read_from_replica?(session, &block)
      # TODO: Implement good defaults for resolving requests
      # For now, we'll always read from replica.
      true
    end
  end
end
