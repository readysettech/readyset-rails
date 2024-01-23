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
    context 'when Rails.env.development? is true' do
      it 'adds a query_log_tag for routing to Readyset' do
        # Setup
        rails_env = 'development'.inquiry # Allows it to respond to development?
        allow(Rails).to receive(:env).and_return(rails_env)
        Readyset::Railtie.setup_query_annotator

        # Verify
        expect(Rails.configuration.active_record.query_log_tags).to include(
          {
            destination: ->(context) do
              ActiveRecord::Base.connection_db_config.name
            end,
          }
        )
      end
    end

    context 'when Rails.env.development? is false' do
      it 'logs a warning about query log tags being disabled or unavailable' do
        # Setup
        # Rails.env
        rails_env = 'production'.inquiry # Should only be available in a development environment
        allow(Rails).to receive(:env).and_return(rails_env)
        allow(Rails.logger).to receive(:warn)

        # Exercise
        Readyset::Railtie.setup_query_annotator

        # Verify
        expect(Rails.logger).to have_received(:warn).with(anything)
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
