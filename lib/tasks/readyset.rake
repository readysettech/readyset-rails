# lib/tasks/readyset.rake

namespace :readyset do
  desc 'Creates caches for all of the supported queries on ReadySet'
  task cache_supported_queries: :environment do
    Readyset::Query.cache_all_supported!
  end

  desc 'Drops all the caches on ReadySet'
  task drop_all_caches: :environment do
    Readyset::Query.drop_all_caches!
  end

  desc 'Prints a list of all the cached queries on ReadySet'
  task all_caches: :environment do
    Readyset::Query.all_cached.each do |query|
      puts query.inspect
    end
  end
end
