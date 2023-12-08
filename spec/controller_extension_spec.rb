# spec/readyset/controller_extension_spec.rb

require 'readyset/controller_extension'

RSpec.describe Readyset::ControllerExtension, type: :controller do
  # Global Set-up
  controller(ActionController::Base) do
    # Main point-of-interest in our fake controller
    # This line specifies that these queries will be re-routed
    route_to_readyset only: [:index, :show]

    def index
      @posts = Post.where(active: true)
      render plain: 'Index'
    end

    def show
      @post = Post.find(params[:id])
      render plain: 'Show'
    end

    def create
      Post.create(params[:post])
      render plain: 'Create'
    end
  end

  before do
    # Need a way to clean this up
    routes.draw do
      get 'index' => 'anonymous#index'
      get 'show/:id' => 'anonymous#show'
      post 'create' => 'anonymous#create'
    end

    # Our fake queries
    stub_const('Post', Class.new)
    allow(Post).to receive(:where).and_return([])
    allow(Post).to receive(:find).and_return(nil)
    allow(Post).to receive(:create)

    allow(Readyset).to receive(:route).and_yield
  end

  describe '#route_to_readyset' do
    before do
      allow(controller.class).to receive(:around_action)
    end

    def expect_around_action_called_with(*expected_args, &block)
      expect(controller.class).to have_received(:around_action).with(*expected_args, &block)
    end

    context 'when delegating to around_action' do
      it 'delegates arguments unchanged to around_action' do
        # Arguments based off of _insert_callbacks
        # callbacks
        action = :test_action
        options_hash = { only: [:index, :show] }

        # optional block
        test_block = proc { 'test block content' }

        controller.class.route_to_readyset(action, options_hash, &test_block)

        expect_around_action_called_with(action, options_hash, test_block) do |&block|
          expect(block).to eq(test_block)
        end
      end
    end

    context 'with a single action' do
      it 'passes a single action symbol to around_action' do
        controller.class.route_to_readyset :index
        expect_around_action_called_with(:index)
      end
    end

    context 'with only option' do
      it 'passes :only option with multiple actions to around_action' do
        controller.class.route_to_readyset only: [:index, :show]
        expect_around_action_called_with(only: [:index, :show])
      end
    end

    context 'with except option' do
      it 'passes :except option to around_action' do
        controller.class.route_to_readyset except: :index
        expect_around_action_called_with(except: :index)
      end
    end

    context 'with multiple options and a block' do
      it 'accepts multiple options and a block' do
        block_conditional = proc {}

        controller.class.route_to_readyset :show, only: [:index, :show], if: block_conditional

        expect_around_action_called_with(:show, { only: [:index, :show], if: block_conditional })
      end
    end
  end
end
