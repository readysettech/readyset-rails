module Readyset
  # Represents the result of an `EXPLAIN CREATE CACHE` invocation on ReadySet.
  class Explain
    attr_reader :id, :text, :supported

    # Gets information about the given query from ReadySet, including whether it's supported to be
    # cached, its current status, the rewritten query text, and the query ID.
    #
    # The information about the given query is retrieved by invoking `EXPLAIN CREATE CACHE FROM` on
    # ReadySet.
    #
    # @param [String] a query about which information should be retrieved
    # @return [Explain]
    def self.call(query)
      raw_results = Readyset.raw_query("EXPLAIN CREATE CACHE FROM #{query}")
      from_readyset_results(**raw_results.first.to_h.symbolize_keys)
    end

    # Creates a new `Explain` with the given attributes.
    #
    # @param [String] id the ID of the query
    # @param [String] text the query text
    # @param [Symbol] supported the supported status of the query
    # @return [Explain]
    def initialize(id:, text:, supported:) # :nodoc:
      @id = id
      @text = text
      @supported = supported
    end

    # Compares `self` with another `Explain` by comparing them attribute-wise.
    #
    # @param [Explain] other the `Explain` to which `self` should be compared
    # @return [Boolean]
    def ==(other)
      id == other.id &&
        text == other.text &&
        supported == other.supported
    end

    # Returns true if the explain information returned by ReadySet indicates that the query is
    # unsupported.
    #
    # @return [Boolean]
    def unsupported?
      supported == :unsupported
    end

    private

    def self.from_readyset_results(**attributes)
      new(
        id: attributes[:'query id'],
        text: attributes[:query],
        supported: attributes[:'readyset supported'].to_sym,
      )
    end
    private_class_method :from_readyset_results
  end
end
