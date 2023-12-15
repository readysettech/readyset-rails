# lib/readyset/configuration.rb

# The Readyset module provides a namespace for the Readyset integration.
module Readyset
  # Configuration class for Readyset integration.
  #
  # This class is used to configure aspects of the Readyset cache system,
  # particularly in relation to its interaction with ActiveRecord.
  class Configuration
    # @!attribute [rw] shard
    #   @return [Symbol] the symbol representing the shard name for Readyset.

    attr_accessor :shard

    # Initializes a new instance of the Configuration class.
    #
    # By default, it sets the shard to :readyset, which can be overridden
    # through the accessor.
    def initialize
      @shard = :readyset
    end
  end
end
