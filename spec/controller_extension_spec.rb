# spec/readyset/controller_extension_spec.rb

require "rails_helper"
require "readyset/controller_extension"

# We're only using the controller helpers
RSpec.describe Readyset::ControllerExtension, type: :controller do

  # Mock controller to test our around_action
  controller(ActionController::Base) do

    # Passes the :index action to ControllerExtension
    route_to_readyset :index

    def index
      @posts = Post.where(active: true)
      @users = User.all
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

    stub_const("Post", Class.new)
    stub_const("User", Class.new)
    allow(Post).to receive(:where).and_return([])
    allow(User).to receive(:all).and_return([])
    allow(Post).to receive(:find).and_return(nil)
  end

  describe "#route_to_readyset" do
    it "routes queries in the index action to the replica database" do
      # It's yielding the code within the action,
      # which would be the queries.
      expect(ActiveRecord::Base).to receive(:connected_to).with(role: :replica_db_role).and_yield
      get :index
    end

    it "does not route queries in the show action to the replica database" do
      expect(ActiveRecord::Base).not_to receive(:connected_to).with(role: :replica_db_role)
      get :show, params: { id: 1 }
    end
  end
end
