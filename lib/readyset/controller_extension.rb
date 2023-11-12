# lib/readyset/controller_extension.rb

module Readyset
  module ControllerExtension
    extend ActiveSupport::Concern

    # Our railtie will make the following available in controllers
    included do
      def self.route_to_readyset(*actions)
        around_action only: actions do |_controller, action|
          # TODO: The role should be flexible
          ActiveRecord::Base.connected_to(role: :replica_db_role) do
            action.call # All queries will connect to the replica
          end
        end
      end
    end
  end
end
