# spec/railtie_spec.rb

require "rails_helper"

RSpec.xdescribe ReadySet::Railtie, type: :controller do
  controller(ActionController::Base) do
    # Define a test action
    def index
      render plain: "Test"
    end
  end

  before do
    routes.draw do
      get "index" => "anonymous#index"
    end
  end

  it "includes ControllerExtension into ActionController::Base" do
    expect(controller.class.ancestors).to include(ReadySet::ControllerExtension)
  end
end
