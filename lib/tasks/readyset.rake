require 'colorize'
require 'erb'
require 'progressbar'
require 'terminal-table'

namespace :readyset do
  desc 'Creates a cache from the given query ID'
  task :create_cache, [:id] => :environment do |_, args|
    if args.key?(:id)
      Readyset.create_cache!(id: args[:id])
    else
      puts 'A query ID must be passed to this task'
    end
  end

  desc 'Creates a cache from the given query ID whose queries will never fall back to the ' \
    'primary database'
  task :create_cache_always, [:id] => :environment do |_, args|
    if args.key?(:id)
      Readyset.create_cache!(id: args[:id], always: true)
    else
      puts 'A query ID must be passed to this task'
    end
  end

  desc 'Prints a list of all the queries that ReadySet has proxied'
  task proxied_queries: :environment do
    rows = Readyset::Query::ProxiedQuery.all.map do |q|
      [q.id, q.text, q.supported, q.count]
    end
    table = Terminal::Table.new(headings: [:id, :text, :supported, :count], rows: rows)

    puts table
  end

  namespace :proxied_queries do
    desc 'Creates caches for all of the supported queries on ReadySet'
    task cache_all_supported: :environment do
      Readyset::Query::ProxiedQuery.cache_all_supported!
    end

    desc 'Clears the list of proxied queries on ReadySet'
    task drop_all: :environment do
      Readyset.raw_query('DROP ALL PROXIED QUERIES'.freeze)
    end

    desc 'Prints a list of all the queries that ReadySet has proxied that can be cached'
    task supported: :environment do
      rows = Readyset::Query::ProxiedQuery.all.
        select { |query| query.supported == :yes }.
        map { |q| [q.id, q.text, q.count] }
      table = Terminal::Table.new(headings: [:id, :text, :count], rows: rows)

      puts table
    end
  end

  desc 'Prints a list of all the cached queries on ReadySet'
  task caches: :environment do
    rows = Readyset::Query::CachedQuery.all.map do |q|
      [q.id, q.name, q.text, q.always, q.count]
    end
    table = Terminal::Table.new(headings: [:id, :name, :text, :always, :count], rows: rows)

    puts table
  end

  namespace :caches do
    desc 'Drops the cache with the given name'
    task :drop, [:name] => :environment do |_, args|
      if args.key?(:name)
        Readyset.drop_cache!(args[:name])
      else
        puts 'A cache name must be passed to this task'
      end
    end

    desc 'Drops all the caches on ReadySet'
    task drop_all: :environment do
      Readyset::Query::CachedQuery.drop_all!
    end

    desc 'Dumps the set of caches that currently exist on ReadySet to a file'
    task dump: :environment do
      template = File.read(File.join(File.dirname(__FILE__), '../templates/caches.rb.tt'))

      queries = Readyset::Query::CachedQuery.all

      f = File.new(Readyset.configuration.migration_path, 'w')
      f.write(ERB.new(template, trim_mode: '-').result(binding))
      f.close
    end

    desc 'Synchronizes the caches on ReadySet such that the caches on ReadySet match those ' \
      'listed in db/readyset_caches.rb'
    task migrate: :environment do
      file = Readyset.configuration.migration_path

      # We load the definition of the `Readyset::Caches` subclass in the context of a
      # container object so we can be sure that we are never re-opening a previously-defined
      # subclass of `Readyset::Caches`. When the container object is garbage collected, the
      # definition of the `Readyset::Caches` subclass is garbage collected too
      container = Object.new
      container.instance_eval(File.read(file))
      caches_in_migration_file = container.singleton_class::ReadysetCaches.caches.index_by(&:text)
      caches_on_readyset = Readyset::Query::CachedQuery.all.index_by(&:text)

      to_drop = caches_on_readyset.keys - caches_in_migration_file.keys
      to_create = caches_in_migration_file.keys - caches_on_readyset.keys

      if to_drop.size.positive? || to_create.size.positive?
        dropping = 'Dropping'.red
        creating = 'creating'.green
        print "#{dropping} #{to_drop.size} caches and #{creating} #{to_create.size} caches. " \
          'Continue? (y/n) '
        $stdout.flush
        y_or_n = STDIN.gets.strip

        if y_or_n == 'y'
          if to_drop.size.positive?
            bar = ProgressBar.create(title: 'Dropping caches', total: to_drop.size)

            to_drop.each do |text|
              bar.increment
              Readyset.drop_cache!(caches_on_readyset[text].name)
            end
          end

          if to_create.size.positive?
            bar = ProgressBar.create(title: 'Creating caches', total: to_create.size)

            to_create.each do |text|
              bar.increment
              cache = caches_in_migration_file[text]
              Readyset.create_cache!(sql: text, always: cache.always)
            end
          end
        end
      else
        puts 'Nothing to do'
      end
    end
  end

  desc 'Prints status information about ReadySet'
  task status: :environment do
    rows = Readyset.raw_query('SHOW READYSET STATUS'.freeze).
      map { |result| [result['name'], result['value']] }
    table = Terminal::Table.new(rows: rows)

    puts table
  end

  desc 'Prints information about the tables known to ReadySet'
  task tables: :environment do
    rows = Readyset.raw_query('SHOW READYSET TABLES'.freeze).
      map { |result| [result['table'], result['status'], result['description']] }
    table = Terminal::Table.new(headings: [:table, :status, :description], rows: rows)

    puts table
  end
end
