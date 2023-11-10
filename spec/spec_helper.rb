# frozen_string_literal: true

require "bundler/setup"
require "combustion"
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
Bundler.require :default, :development
Bundler.setup
Combustion.initialize! :all
# spec/spec_helper.rb

require "readyset"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
