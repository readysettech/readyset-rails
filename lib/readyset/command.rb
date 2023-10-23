# lib/readyset-rails/command.rb

module Readyset
  class Command
    def self.create_cache(name, query, always: false)
      cache_command = always ? "CREATE CACHE ALWAYS [#{name}] FROM #{query};" : "CREATE CACHE [#{name}] FROM #{query};"
      Connection.establish.execute(cache_command)
    end

    def self.show_caches(query_id = nil)
      query_id ? Connection.establish.execute("SHOW CACHES where query_id = #{query_id};") : Connection.establish.execute("SHOW CACHES;")
    end

    def self.drop_cache(id)
      Connection.establish.execute("DROP CACHE #{id}")
    end
  end
end
