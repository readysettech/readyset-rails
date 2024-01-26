# frozen_string_literal: true

require 'pry'
require 'bundler/setup'
Bundler.setup

require 'combustion'
require 'factory_bot'
require 'timecop'

require_relative 'shared_examples'

Combustion.initialize! :action_controller, :active_record, database_reset: false do
  config.active_record.query_log_tags_enabled = true
end

require 'readyset'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions

    loop do
      completed = Readyset.raw_query('SHOW READYSET STATUS').any? do |row|
        row['name'] == 'Snapshot Status' && row['value'] == 'Completed'
      end

      if completed
        break
      else
        sleep(1.second)
      end
    end
  end

  config.before(:each) do
    Readyset::Query::CachedQuery.drop_all!
    Readyset::Query::ProxiedQuery.drop_all!
    ActiveRecord::Base.connection.execute('TRUNCATE cats RESTART IDENTITY')
  end
end

def build_and_create_cache(cache, **kwargs)
  cache = build(cache, **kwargs)

  text = cache.text.gsub('"public".', '')
  Readyset.create_cache!(sql: text, always: cache.always, name: cache.name)
  cache
end

def build_and_execute_proxied_query(query, **kwargs)
  build(query, **kwargs).tap do |q|
    Readyset.raw_query(q.text.gsub('$1', "'test'"))
  end
end

def eventually(attempts: 40, sleep: 0.5.seconds)
  attempts.times do
    if yield
      break
    else
      sleep(sleep)
    end
  rescue StandardError
    sleep(sleep)
  end
end
