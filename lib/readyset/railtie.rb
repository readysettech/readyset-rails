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

    # This Railtie sets up the ReadySet connection pools, which prevents users from needing to
    # add a call to `ActiveRecord::Base.connects_to` in their ApplicationRecord class.
    initializer 'readyset.connection_pools' do |app|
      ActiveSupport.on_load(:after_initialize) do
        shard = Readyset.config.shard

        ActiveRecord::Base.connected_to(role: ActiveRecord.reading_role, shard: shard) do
          ActiveRecord::Base.establish_connection(:readyset)
        end

        ActiveRecord::Base.connected_to(role: ActiveRecord.writing_role, shard: shard) do
          ActiveRecord::Base.establish_connection(:readyset)
        end
      end
    end

    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), '../tasks/*.rake')].each { |f| load f }
    end
  end
end
