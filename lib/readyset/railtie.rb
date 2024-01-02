# lib/readyset/railtie.rb

module Readyset
  class Railtie < Rails::Railtie
    initializer 'readyset.action_controller' do
      ActiveSupport.on_load(:action_controller) do
        prepend Readyset::ControllerExtension
      end
    end

    initializer 'readyset.active_record' do |app|
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.prepend(Readyset::ModelExtension)
        ActiveRecord::Relation.prepend(Readyset::RelationExtension)
      end
    end

    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), '../tasks/*.rake')].each { |f| load f }
    end
  end
end
