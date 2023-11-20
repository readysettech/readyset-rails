# spec/readyset/controller_extension_spec.rb

require "rails_helper"
require "readyset/controller_extension"

RSpec.describe ReadySet::ControllerExtension, type: :controller do
  # Global Set-up
  controller(ActionController::Base) do
    # NOTE: Not required as it's setup by the ReadySet Railtie
    # include ReadySet::ControllerExtension

    # Main point-of-interest in our fake controller
    # This line specifies that these queries will be re-routed
    route_to_readyset only: [:index, :show]

    def index
      @posts = Post.where(active: true)
      render plain: "Index"
    end

    def show
      @post = Post.find(params[:id])
      render plain: "Show"
    end

    def create
      Post.create(params[:post])
      render plain: "Create"
    end
  end

  before do
    # Need a way to clean this up
    routes.draw do
      get "index" => "anonymous#index"
      get "show/:id" => "anonymous#show"
      post "create" => "anonymous#create"
    end

    # Our fake queries
    stub_const("Post", Class.new)
    allow(Post).to receive(:where).and_return([])
    allow(Post).to receive(:find).and_return(nil)
    allow(Post).to receive(:create)
  end

  describe "#route_to_readyset" do

    # Lacks full coverage of possible #around_action parameters, but gets the point across
    # TODO: Refactor this spec and the mock controller/queries + params
    # TODO: Change route_to_readyset params for full coverage
    # TODO: Test to re-route a single query out of an action

    # Sort of a leftover when it was just a symbol
    context "when accessing the index action" do
      it "routes queries to the replica database" do
        # Make sure it's working within the replica "context"
        # and it is executing the queries via yield
        expect(ActiveRecord::Base).to receive(:connected_to).with(role: :replica_db_role).and_yield
        get :index
      end
    end

    # Check if the options are passing in correctly
    context "when accessing the show action with :only option" do
      it "routes queries to the replica database" do
        expect(ActiveRecord::Base).to receive(:connected_to).with(role: :replica_db_role).and_yield
        get :show, params: { id: 1 }
      end
    end

    # Ensure that non-specified actions aren't getting re-routed
    context "when accessing an action not included in :only" do
      it "does not route queries to the replica database" do
        expect(ActiveRecord::Base).not_to receive(:connected_to).with(role: :replica_db_role)
        post :create, params: { post: { title: "New Post" } }
      end
    end
  end
end
