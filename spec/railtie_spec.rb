# spec/railtie_spec.rb

require 'rails_helper'

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
