# lib/ready_set/railtie.rb

module ReadySet
  class Railtie < Rails::Railtie
    initializer 'readyset.configure_rails_initialization' do |app|
      app.middleware.use ReadySet::Middleware
    end
  end
end
