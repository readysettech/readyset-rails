# spec/railtie_spec.rb

require 'spec_helper'

RSpec.describe Readyset::Railtie do
  describe 'readyset.action_controller', type: :controller do
    controller(ActionController::Base) do
      # Define a test action
      def index
        render plain: 'Test'
      end
    end

    before do
      routes.draw do
        get 'index' => 'anonymous#index'
      end
    end

    it 'includes ControllerExtension into ActionController::Base' do
      expect(controller.class.ancestors).to include(Readyset::ControllerExtension)
    end
  end

  describe 'readyset.active_record' do
    it 'includes RelationExtension into ActiveRecord::Relation' do
      expect(ActiveRecord::Relation.ancestors).to include(Readyset::RelationExtension)
    end
  end
  describe 'readyset.query_annotator' do
    context 'when query_log_tags_enabled is true' do
      before do
        config = Rails.configuration.active_record
        allow(config).to receive(:query_log_tags_enabled).and_return(true)
      end

      it 'adds a query_log_tag for routing to Readyset' do
        # Exercise
        # Here we are assuming that Readyset::QueryAnnotator.routing_to_readyset? returns a value
        allow(Readyset::QueryAnnotator).to receive(:routing_to_readyset?).and_return(true)

        # Verify
        expect(Rails.configuration.active_record.query_log_tags).to include(
          a_hash_including(routed_to_readyset?: an_instance_of(Proc))
        )
      end
    end

    xcontext 'when query_log_tags_enabled is false' do
      before do
        config = Rails.configuration.active_record
        allow(config).to receive(:query_log_tags_enabled).and_return(false)
      end

      it 'logs a warning about query log tags being disabled or unavailable' do
        allow(Rails.logger).to receive(:warn)
        expect(Rails.logger).to receive(:warn)
      end
    end
  end

  describe 'readyset.connection_pools' do
    it 'sets up connection pools for both the reading and writing roles' do
      pools = ActiveRecord::Base.connection_handler.connection_pools
      readyset_pool = pools.find { |pool| pool.shard == Readyset.config.shard }

      expect(readyset_pool).not_to be_nil
      expected_config = ActiveRecord::Base.
        configurations.
        configs_for(name: Readyset.config.shard.to_s, env_name: Rails.env, include_hidden: true)
      expect(readyset_pool.db_config).to eq(expected_config)
      expect(readyset_pool.connection_class).to eq(ActiveRecord::Base)
    end
  end
end
