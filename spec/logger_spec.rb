# spec/readyset-rails/logger_spec.rb

require 'spec_helper'
require 'readyset/logger.rb'

RSpec.describe Readyset::Logger do
  it_behaves_like 'a logger method', :debug, 'This is a debug message'
  it_behaves_like 'a logger method', :info, 'This is an info message'
  it_behaves_like 'a logger method', :warn, 'This is a warn message'
  it_behaves_like 'a logger method', :error, 'This is an error message'
  it_behaves_like 'a logger method', :fatal, 'This is an fatal message'
  it_behaves_like 'a logger method', :unknown, 'This is an unknown message'

  context 'with invalid log level' do
    it 'raises an error' do
      expect { Readyset::Logger.log(:invalid_level, 'message') }.to raise_error(ArgumentError)
    end
  end
end
