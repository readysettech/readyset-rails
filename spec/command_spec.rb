# command_spec.rb
# spec/readyset-rails/command_spec.rb

require "spec_helper"
require_relative "./../lib/readyset/command.rb"
require_relative "./../lib/readyset.rb"

RSpec.describe Readyset::Command do
  let(:connection_double) { instance_double("ActiveRecord::ConnectionAdapters::AbstractAdapter") }

  before do
    allow(Readyset::Connection).to receive(:establish).and_return(connection_double)
    allow(connection_double).to receive(:execute)
  end

  describe ".create_cache" do
    context "when always is set to true" do
      it "executes the correct SQL command" do
        described_class.create_cache("test_cache", "SELECT * FROM test", always: true)
        expect(connection_double).to have_received(:execute).with("CREATE CACHE ALWAYS [test_cache] FROM SELECT * FROM test;")
      end
    end

    context "when always is not set" do
      it "executes the correct SQL command" do
        described_class.create_cache("test_cache", "SELECT * FROM test")
        expect(connection_double).to have_received(:execute).with("CREATE CACHE [test_cache] FROM SELECT * FROM test;")
      end
    end
  end

  describe ".show_caches" do
    context "when a query_id is provided" do
      it "executes the correct SQL command" do
        described_class.show_caches(1)
        expect(connection_double).to have_received(:execute).with("SHOW CACHES where query_id = 1;")
      end
    end

    context "when no query_id is provided" do
      it "executes the correct SQL command" do
        described_class.show_caches
        expect(connection_double).to have_received(:execute).with("SHOW CACHES;")
      end
    end
  end

  describe ".drop_cache" do
    it "executes the correct SQL command" do
      described_class.drop_cache(1)
      expect(connection_double).to have_received(:execute).with("DROP CACHE 1")
    end
  end
end
