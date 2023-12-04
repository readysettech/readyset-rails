# middleware_spec.rb

require 'spec_helper'
require_relative './../lib/readyset/middleware'

RSpec.describe Readyset::Middleware do
  let(:app) { double('App', call: true) }
  let(:env) { {} }
  let(:middleware) { Readyset::Middleware.new(app) }

  it 'initializes with an app' do
    expect(middleware.instance_variable_get(:@app)).to eq(app)
  end

  it 'calls the app with the environment' do
    expect(app).to receive(:call).with(env)
    middleware.call(env)
  end
end
