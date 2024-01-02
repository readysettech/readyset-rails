module Readyset
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
