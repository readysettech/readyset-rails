# lib/ready_set/railtie.rb

module ReadySet
  class Railtie < Rails::Railtie
    initializer 'readyset.configure_rails_initialization' do |app|
      app.middleware.use ReadySet::Middleware
    end
    initializer 'readyset.action_controller' do
      ActiveSupport.on_load(:action_controller) do
        include ReadySet::ControllerExtension
      end
    end
  end
end
