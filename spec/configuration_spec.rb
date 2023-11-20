# configuration_spec.rb
# spec/readyset-rails/configuration_spec.rb

require "spec_helper"
require_relative "./../lib/readyset/configuration.rb"

# TODO: Correctly mock the configuration
RSpec.describe Readyset::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      config = Readyset::Configuration.new

      expect(config.connection_url).to eq(ENV["READYSET_URL"] || "sqlite3://:@:/db/combustion_test.sqlite")
      expect(config.database_selector).to eq({ delay: 2.seconds })
      expect(config.database_resolver).to eq(Readyset::DefaultResolver)
      expect(config.database_resolver_context).to be_nil
    end
  end

  describe "#connection_url" do
    context "when READYSET_URL is set" do
      before { ENV["READYSET_URL"] = "custom_url" }
      after { ENV.delete("READYSET_URL") }

      it "returns the value from the environment variable" do
        expect(config.connection_url).to eq("custom_url")
      end
    end

    context "when READYSET_URL is not set" do
      it "returns the default connection URL" do
        expect(config.connection_url).to eq("sqlite3://:@:/db/combustion_test.sqlite")
      end
    end
  end
end
