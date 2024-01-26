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
      context 'when query log tags are enabled' do
        it 'adds a query_log_tag for routing to Readyset' do
          # Setup
          rails_env = 'development'.inquiry # Allows it to respond to development?
          allow(Rails).to receive(:env).and_return(rails_env)
          allow(Rails.configuration.active_record).to receive(:query_log_tags_enabled).
            and_return(true)
          expected_tag = {
            destination: ->(context) do
              ActiveRecord::Base.connection_db_config.name
            end,
          }
          allow(Rails.configuration.active_record.query_log_tags).to receive(:<<).with(expected_tag)
          Readyset::Railtie.setup_query_annotator

          # Verify
          expect(Rails.configuration.active_record.query_log_tags).to have_received(:<<).
            with(expected_tag)
        end
      end

      context 'when query log tags are not enabled' do
        it 'logs a warning about query log tags being disabled' do
          # Setup
          rails_env = 'development'.inquiry # Allows it to respond to development?
          allow(Rails).to receive(:env).and_return(rails_env)
          allow(Rails.configuration.active_record).to receive(:query_log_tags_enabled).
            and_return(false)

          allow(Rails.logger).to receive(:warn).with(anything)

          # Execute
          Readyset::Railtie.setup_query_annotator

          # Verify
          expect(Rails.logger).to have_received(:warn).with(anything)
        end

        it 'does not add a query_log_tag for routing to Readyset' do
          # Setup
          rails_env = 'development'.inquiry # Allows it to respond to development?
          allow(Rails).to receive(:env).and_return(rails_env)
          allow(Rails.configuration.active_record).to receive(:query_log_tags_enabled).
            and_return(false)
          allow(Rails.configuration.active_record.query_log_tags).to receive(:<<)
          Readyset::Railtie.setup_query_annotator

          # Verify
          expect(Rails.configuration.active_record.query_log_tags).not_to have_received(:<<)
        end
      end
    end

    context 'when Rails.env.test? is true' do
      context 'when query log tags are enabled' do
        it 'adds a query_log_tag for routing to Readyset' do
          # Setup
          rails_env = 'test'.inquiry # Allows it to respond to test?
          allow(Rails).to receive(:env).and_return(rails_env)
          allow(Rails.configuration.active_record).to receive(:query_log_tags_enabled).
            and_return(true)
          expected_tag = {
            destination: ->(context) do
              ActiveRecord::Base.connection_db_config.name
            end,
          }
          allow(Rails.configuration.active_record.query_log_tags).to receive(:<<).with(expected_tag)
          Readyset::Railtie.setup_query_annotator

          # Verify
          expect(Rails.configuration.active_record.query_log_tags).to have_received(:<<).
            with(expected_tag)
        end
      end

      context 'when query log tags are not enabled' do
        it 'logs a warning about query log tags being disabled' do
          # Setup
          rails_env = 'test'.inquiry # Allows it to respond to test?
          allow(Rails).to receive(:env).and_return(rails_env)
          allow(Rails.configuration.active_record).to receive(:query_log_tags_enabled).
            and_return(false)

          allow(Rails.logger).to receive(:warn).with(anything)

          # Execute
          Readyset::Railtie.setup_query_annotator

          # Verify
          expect(Rails.logger).to have_received(:warn).with(anything)
        end

        it 'does not add a query_log_tag for routing to Readyset' do
          # Setup
          rails_env = 'test'.inquiry # Allows it to respond to development?
          allow(Rails).to receive(:env).and_return(rails_env)
          allow(Rails.configuration.active_record).to receive(:query_log_tags_enabled).
            and_return(false)
          allow(Rails.configuration.active_record.query_log_tags).to receive(:<<)
          Readyset::Railtie.setup_query_annotator

          # Verify
          expect(Rails.configuration.active_record.query_log_tags).not_to have_received(:<<)
        end
      end
    end

    context 'when Rails.env.development? and Rails.env.test? are both false' do
      it 'does not add a query_log_tag for routing to Readyset' do
        # Setup
        rails_env = 'production'.inquiry # Allows it to respond to development?
        allow(Rails).to receive(:env).and_return(rails_env)
        allow(Rails.configuration.active_record).to receive(:query_log_tags_enabled).
          and_return(true)
        allow(Rails.configuration.active_record.query_log_tags).to receive(:<<)
        Readyset::Railtie.setup_query_annotator

        # Verify
        expect(Rails.configuration.active_record.query_log_tags).not_to have_received(:<<)
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
