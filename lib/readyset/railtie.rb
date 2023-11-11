# lib/readyset/railtie.rb

module Readyset
  class Railtie < Rails::Railtie
    initializer "readyset.configure_rails_initialization" do |app|
      app.middleware.use Readyset::Middleware
    end
    initializer "readyset.action_controller" do
      ActiveSupport.on_load(:action_controller) do
        include Readyset::ControllerExtension
      end
    end
  end
end
