# spec/configuration_spec.rb

require 'spec_helper'
require 'readyset/configuration'

RSpec.describe Readyset::Configuration do
  context 'when database.yml present' do
    it 'defaults to the url defined in config/database.yml' do
      # Setup
      # add env var to test that `database.yml` is the default
      allow(ENV).to receive(:[]).with('READYSET_URL').and_return('env_db_url')
      allow(Rails).to receive_message_chain(:root,
                                            :join).and_return('spec/internal/config/database.yml')
      allow(File).to receive(:read).and_return('test: readyset: url: "test_db_url"')

      # safe_load is standard practice
      allow(YAML).to receive(:safe_load).
        and_return({ 'test' => { 'readyset' => { 'url' => 'test_db_url' } } })

      # Exercise
      config = described_class.new

      # Verify
      expect(config.database_url).to eq 'test_db_url'
    end
  end

  context 'when database_url ENV var is specified' do
    it 'is used instead of the url in config/database.yml' do
      # Setup
      allow(ENV).to receive(:[]).with('READYSET_URL').and_return('env_db_url')

      # Exercise
      config = described_class.new

      # Verify
      expect(config.database_url).to eq 'env_db_url'
    end
  end

  context 'when neither config/database.yml nor ENV provides a database_url' do
    it 'logs an error' do
      # Setup
      allow(ENV).to receive(:[]).with('READYSET_URL').and_return(nil)
      allow(Rails).to receive_message_chain(:root,
                                            :join).
        and_return('spec/internal/config/database.yml')
      allow(File).to receive(:exist?).and_return(false)
      allow(Rails.logger).to receive(:error)

      # Exercise
      config = described_class.new

      # Verify
      expect(config.database_url).to be_nil
      expect(Rails.logger).to have_received(:error).once
    end
  end
end
