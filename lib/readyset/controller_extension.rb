# lib/readyset/controller_extension.rb

require_relative "./request_processor"

module Readyset
  module ControllerExtension
    extend ActiveSupport::Concern

    included do
      # TODO: route_to_readyset if: -> { custom_logic }
      # TODO: Accept the same options as `around_action`
      def self.readyset_cache(*actions)
        around_action only: actions do |controller, block|
          Readyset::RequestProcessor.process { block.call }
        end
      end
    end
  end
end
