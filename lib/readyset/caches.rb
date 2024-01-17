module Readyset
  # Defines the DSL used in the gem's "migration" files. The DSL should be used by inheriting
  # from this class and invoking the `.cache` class method to define new caches.
  class Caches
    class << self
      attr_reader :caches
    end

    def self.cache(id:, always: false)
      @caches ||= Set.new

      query = yield

      @caches << Query::CachedQuery.new(
        id: id,
        text: query.strip,
        always: always,
      )
    end
  end
end
