# lib/readyset/middleware.rb

# Mentioned in the docs:
# The core time extension is necessary for the default 2-second delay
require 'active_support/core_ext/integer/time'
require 'action_dispatch'

module Readyset
  class Middleware
    def initialize(app)
      @app = app
      @resolver_klass = Readyset.configuration.database_resolver ||
        ActiveRecord::Middleware::DatabaseSelector::Resolver
      @context_klass = Readyset.configuration.database_resolver_context ||
        ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      select_database(request) do
        @app.call(env)
      end
    end

    private

    def select_database(request)
      # This might involve looking at request parameters, headers, session data, etc.
      # Here, you'd implement logic to determine which database to use based on the request.
      # For simplicity, we're always selecting the replica. Adjust this as needed.

      ActiveRecord::Base.connected_to(role: :reading) do
        yield
      end
    end
  end
end
