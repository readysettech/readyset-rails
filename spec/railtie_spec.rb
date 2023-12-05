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
end
