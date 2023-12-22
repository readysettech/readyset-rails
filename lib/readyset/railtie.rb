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
        ActiveRecord::Relation.prepend(Readyset::RelationExtension)
      end
    end

    initializer 'readyset.query_annotator' do |app|
      ActiveSupport.on_load(:after_intialization) do
        if Rails.configuration.active_record.query_log_tags_enabled
          Rails.configuration.active_record.query_log_tags ||= []
          Rails.configuration.active_record.query_log_tags << {
            routed_to_readyset?: ->(context) do
              Readyset::QueryAnnotator.routing_to_readyset?
            end,
          }
        else
          Rails.logger.warn 'Query log tags are either disabled or unavailable.'
        end
      end
    end
  end
end
