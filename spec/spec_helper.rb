# frozen_string_literal: true

require 'bundler/setup'
Bundler.setup

require 'combustion'
require 'factory_bot'
require 'readyset'
require_relative 'shared_examples'

Combustion.initialize! :action_controller, :active_record do
  config.eager_load = true
end

# This is a bit of a hack. Combustion doesn't appear to support migrating multiple databases, so we
# just copy the primary database file to serve as the database for our fake ReadySet instance
primary_db_file = Rails.configuration.database_configuration['test']['primary']['database']
readyset_db_file = Rails.configuration.database_configuration['test']['readyset']['database']
FileUtils.cp("spec/internal/#{primary_db_file}", "spec/internal/#{readyset_db_file}")

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
  end
end
