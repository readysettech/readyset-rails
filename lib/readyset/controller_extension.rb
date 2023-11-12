# lib/readyset/controller_extension.rb

require_relative "./request_processor"

module Readyset
  module ControllerExtension
    extend ActiveSupport::Concern

    included do
      def self.route_to_readyset(*actions)
        around_action only: actions do |controller, block|
          ActiveRecord::Base.connected_to(role: :replica_db_role) do
            block.call
          end
        end
      end
    end
  end
end
