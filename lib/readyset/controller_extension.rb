module Readyset
  # Module providing controller extensions for routing ActiveRecord queries to a replica database.
  module ControllerExtension
    extend ActiveSupport::Concern

    prepended do
      # Routes ActiveRecord queries in specified actions to a replica database.
      #
      # This method defines an around_action callback that wraps
      # the given actions. Inside the callback,
      # it switches the ActiveRecord connection to a replica database,
      # ensuring that all database queries
      # within the actions are executed against the replica.
      #
      # @param actions [Array<Symbol, String>] A list of action names to which this routing applies.
      # @param options [Hash] Additional options to refine the callback application,
      # such as :only or :except.
      # @param block [Proc] An optional block that can be used for additional
      # logic around the action execution.
      #
      # @example
      #   route_to_readyset :index, :show, only: [:index, :show] do |controller, action_block|
      #     # Custom logic can be placed here
      #   end
      #
      def self.route_to_readyset(*actions, **options, &block)
        # Use double splat (**) to pass options as keyword arguments
        around_action(*actions, **options) do |_controller, action_block|
          Readyset.route do
            action_block.call
          end
        end
      end
    end
  end
end
