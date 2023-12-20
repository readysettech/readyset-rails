require 'colorize'
require 'erb'
require 'progressbar'

namespace :readyset do
  namespace :caches do
    desc 'Dumps the set of caches that currently exist on ReadySet to a file'
    task dump: :environment do
      Rails.application.eager_load!

      template = File.read(File.join(File.dirname(__FILE__), '../templates/caches.rb.tt'))

      queries = Readyset::Query::CachedQuery.all
      f = File.new(Readyset.configuration.migration_path, 'w')
      f.write(ERB.new(template, trim_mode: '-').result(binding))
      f.close
    end

    desc 'Synchronizes the caches on ReadySet such that the caches on ReadySet match those ' \
      'listed in db/readyset_caches.rb'
    task migrate: :environment do
      Rails.application.eager_load!

      file = Readyset.configuration.migration_path

      # We load the definition of the `Readyset::Caches` subclass in the context of a
      # container object so we can be sure that we are never re-opening a previously-defined
      # subclass of `Readyset::Caches`. When the container object is garbage collected, the
      # definition of the `Readyset::Caches` subclass is garbage collected too
      container = Object.new
      container.instance_eval(File.read(file))
      caches = container.singleton_class::ReadysetCaches.caches

      caches_on_readyset = Readyset::Query::CachedQuery.all.index_by(&:id)
      caches_on_readyset_ids = caches_on_readyset.keys.to_set

      caches_in_migration_file = caches.index_by(&:id)
      caches_in_migration_file_ids = caches_in_migration_file.keys.to_set

      to_drop_ids = caches_on_readyset_ids - caches_in_migration_file_ids
      to_create_ids = caches_in_migration_file_ids - caches_on_readyset_ids

      if to_drop_ids.size.positive? || to_create_ids.size.positive?
        dropping = 'Dropping'.red
        creating = 'creating'.green
        print "#{dropping} #{to_drop_ids.size} caches and #{creating} #{to_create_ids.size} " \
          'caches. Continue? (y/n) '
        $stdout.flush
        y_or_n = STDIN.gets.strip

        if y_or_n == 'y'
          if to_drop_ids.size.positive?
            bar = ProgressBar.create(title: 'Dropping caches', total: to_drop_ids.size)

            to_drop_ids.each do |id|
              bar.increment
              Readyset.drop_cache!(name_or_id: id)
            end
          end

          if to_create_ids.size.positive?
            bar = ProgressBar.create(title: 'Creating caches', total: to_create_ids.size)

            to_create_ids.each do |id|
              bar.increment
              Readyset.create_cache!(id: id)
            end
          end
        end
      else
        puts 'Nothing to do'
      end
    end
  end

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
