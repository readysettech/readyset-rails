module Readyset
  # Module providing controller extensions for routing ActiveRecord queries to a replica database.
  module ControllerExtension
    extend ActiveSupport::Concern

    prepended do
      # Sets up an `around_action` for a specified set of controller actions.
      # This method is used to route the specified actions through Readyset,
      # allowing ActiveRecord queries within those actions to be handled by a replica database.
      #
      # @example
      #   route_to_readyset only: [:index, :show]
      #   route_to_readyset :index
      #   route_to_readyset except: :index
      #   route_to_readyset :show, only: [:index, :show], if: -> { some_condition }
      #
      # @param args [Array<Symbol, Hash>] A list of actions and/or options dictating when the
      # around_action should apply.
      #   The options can include Rails' standard `:only`, `:except`, and conditionals like `:if`.
      # @yield [_controller, action_block] An optional block that will execute around the actions.
      #   Yields the block from the controller action.
      # @yieldparam _controller [ActionController::Base] Param is unused.
      # @yieldparam action_block [Proc] The block passed along with the action.
      #
      def self.route_to_readyset(*args, &block)
        around_action(*args, *block) do |_controller, action_block|
          Readyset.route do
            action_block.call
          end
        end
      end
    end
  end
end
