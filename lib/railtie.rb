# lib/railtie.rb

require "rails"

module Readyset
  class Railtie < Rails::Railtie
    initializer "readyset.configure_rails_initialization" do |app|
      app.middleware.use Readyset::Middleware
    end
  end
end
