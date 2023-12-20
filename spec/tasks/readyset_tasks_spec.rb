# spec/tasks/readyset_tasks_spec.rb

require 'rails_helper'
require 'rake'

RSpec.describe 'ReadySet tasks', type: :task do
  before :all do
    Rake.application.rake_require('tasks/readyset')
    Rake::Task.define_task(:environment)
  end

  describe 'readyset:cache_supported_queries' do
    it 'creates caches for all supported queries' do
      # Setup
      allow(Readyset::Query).to receive(:cache_all_supported!)

      # Exercise
      Rake::Task['readyset:cache_supported_queries'].execute

      # Verify
      expect(Readyset::Query).to have_received(:cache_all_supported!)
    end
  end
  describe 'readyset:drop_all_caches' do
    it 'drops all caches' do
      # Setup
      allow(Readyset::Query).to receive(:drop_all_caches!)

      # Exercise
      Rake::Task['readyset:drop_all_caches'].execute

      # Verify
      expect(Readyset::Query).to have_received(:drop_all_caches!)
    end
  end

  describe 'readyset:all_caches' do
    it 'prints all cached queries' do
      # Setup
      allow(Readyset::Query).to receive(:all_cached).and_return([double, double])

      # Exercise
      Rake::Task['readyset:all_caches'].execute

      # Verify
      expect(Readyset::Query).to have_received(:all_cached)
    end
  end
end
