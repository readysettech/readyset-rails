# spec/readyset/controller_extension_spec.rb

require "rails_helper"
require "ready_set/controller_extension"
require "ready_set/logger"

RSpec.describe ReadySet::ControllerExtension, type: :controller do
  # Global Set-up
  controller(ActionController::Base) do
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

    # Testing accepted params; match around_action
    before do
      allow(controller.class).to receive(:around_action)
    end

    context "with a single action" do
      it "accepts a single action symbol" do
        controller.class.route_to_readyset :index
        expect(controller.class).to have_received(:around_action).with(:index)
      end
    end

    context "with only option" do
      it "accepts :only option with multiple actions" do
        controller.class.route_to_readyset only: [:index, :show]
        expect(controller.class).to have_received(:around_action).with(only: [:index, :show])
      end
    end

    context "with except option" do
      it "accepts :except option" do
        controller.class.route_to_readyset except: :index
        expect(controller.class).to have_received(:around_action).with(except: :index)
      end
    end

    context "with multiple options and a block" do
      it "accepts multiple options and a block" do
        block = proc { }
        controller.class.route_to_readyset :index, only: [:index], if: -> { true }, &block
        expect(controller.class).to have_received(:around_action).
                                      with(:index, only: [:index], if: an_instance_of(Proc))
      end
    end
  end
  describe "integration with ReadySet::Logger" do
    before do
      # Setup to intercept and test the interaction between ControllerExtension and Logger
      allow(controller).to receive(:setup_sql_comment_tag)
    end

    context "when route_to_readyset is used" do
      it "sets up a SQL comment tag via Logger" do
        get :index
        expect(controller).to have_received(:setup_sql_comment_tag).with(:readyset_route, "routed through ReadySet")
      end
    end

    context "when an action not included in route_to_readyset is used" do
      it "does not set up a SQL comment tag via Logger" do
        post :create, params: { post: { title: "New Post" } }
        expect(controller).not_to have_received(:setup_sql_comment_tag)
      end
    end
  end
end
