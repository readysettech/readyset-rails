# lib/request_processor.rb

module Readyset
  class RequestProcessor
    def self.process
      # Extract and process queries here
      yield if block_given?

      # Tag the request for Middleware::DatabaseSelector::Resolver
      Thread.current[:readyset_redirected] = true
    end
  end
end
