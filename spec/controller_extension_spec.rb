# spec/readyset/controller_extension_spec.rb

require "rails_helper"
require "readyset/controller_extension"

RSpec.describe Readyset::ControllerExtension, type: :controller do
  # Define a temporary controller for testing
  controller(ActionController::Base) do

    # TODO: Rename.
    # TODO: Change options passed
    readyset_cache :index, :show

    def index
      @posts = Post.where(active: true)
      render plain: "Index"
    end

    def show
      @post = Post.find(params[:id])
      render plain: "Show"
    end
  end

  before do
    routes.draw do
      get "index" => "anonymous#index"
      get "show/:id" => "anonymous#show"
    end

    # Stubbing or mocking the Post model
    stub_const("Post", Class.new)
    allow(Post).to receive(:where).and_return([])
    allow(Post).to receive(:find).and_return(nil)
  end

  # Ensuring that the around_action is correctly available
  # RequestProcessor is the main behavior to trigger
  describe "#readyset_cache" do
    it "routes the index action through Readyset" do
      expect(Readyset::RequestProcessor).to receive(:process).and_yield
      get :index
    end

    it "routes the show action through Readyset" do
      expect(Readyset::RequestProcessor).to receive(:process).and_yield
      get :show, params: { id: 1 }
    end
  end
end
