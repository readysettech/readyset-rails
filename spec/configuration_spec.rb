# configuration_spec.rb
# spec/readyset-rails/configuration_spec.rb

require "spec_helper"
require_relative "./../lib/readyset/configuration.rb"

RSpec.describe Readyset::Configuration do
  let(:config) { described_class.new }

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
        expect(config.connection_url).to eq("postgres://user:password@localhost:5432/readyset")
      end
    end
  end
end
