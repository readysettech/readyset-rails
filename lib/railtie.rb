# lib/railtie.rb
# lib/readyset/railtie.rb

module Readyset
  class Railtie < Rails::Railtie
    initializer "readyset.insert_middleware" do |app|
      app.middleware.use Readyset::Middleware
    end

    # ... rest of the class ...
  end
end
