# lib/readyset-rails/command.rb

module ReadySet
  class Command
    def self.create_cache(name, query, always: false)
      cache_command =
        if always
          "CREATE CACHE ALWAYS #{name} FROM #{query};"
        else
          "CREATE CACHE #{name} FROM #{query};"
        end

      Connection.establish.execute(cache_command)
    end

    def self.show_caches(query_id: nil)
      if query_id
        Connection.establish.execute('SHOW CACHES where query_id = ?', query_id)
      else
        Connection.establish.execute('SHOW CACHES;')
      end
    end

    def self.drop_cache(id)
      Connection.establish.execute('DROP CACHE ?', id)
    end
  end
end
