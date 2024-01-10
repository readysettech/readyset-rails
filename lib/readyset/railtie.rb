# lib/readyset/railtie.rb

require 'active_record/readyset_connection_handling'

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
        ActiveRecord::Base.prepend(ActiveRecord::ReadysetConnectionHandling)

        ActiveRecord::Relation.prepend(Readyset::RelationExtension)
      end
    end

    # This Railtie sets up the ReadySet connection pools, which prevents users from needing to
    # add a call to `ActiveRecord::Base.connects_to` in their ApplicationRecord class.
    initializer 'readyset.connection_pools' do |app|
      ActiveSupport.on_load(:after_initialize) do
        shard = Readyset.config.shard
        config = ActiveRecord::Base.
          configurations.
          configs_for(name: shard.to_s, env_name: Rails.env, include_hidden: true).
          configuration_hash

        ActiveRecord::Base.connection_handler.
          establish_connection(config, role: ActiveRecord.reading_role, shard: shard)
        ActiveRecord::Base.connection_handler.
          establish_connection(config, role: ActiveRecord.writing_role, shard: shard)
      end
    end

    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), '../tasks/*.rake')].each { |f| load f }
    end
  end
end
