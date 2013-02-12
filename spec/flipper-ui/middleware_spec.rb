require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'

describe Flipper::UI::Middleware do
  include Rack::Test::Methods

  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }

  let(:flipper) {
    Flipper.new(adapter, :instrumenter => ActiveSupport::Notifications)
  }

  def app
    @app ||= begin
      middleware = described_class
      instance = flipper

      Rack::Builder.new do
        use middleware, instance

        map "/" do
          run lambda {|env| [404, {}, []] }
        end
      end.to_app
    end
  end

  describe "GET /flipper" do
    before do
      flipper[:stats].enable
      flipper[:search].enable
      get '/flipper'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end

    it "renders view" do
      last_response.body.should match(/Flipper/)
    end
  end

  describe "GET /flipper/features" do
    before do
      flipper[:new_stats].enable
      flipper[:search].disable
      get '/flipper/features'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end

    it "responds with content type of json" do
      last_response.content_type.should eq('application/json')
    end

    it "renders view" do
      features = json_response
      features.should be_instance_of(Array)

      feature = features[0]
      feature['id'].should eq('new_stats')
      feature['name'].should eq('New Stats')
      feature['state'].should eq('on')
      feature['description'].should eq('Enabled')

      feature = features[1]
      feature['id'].should eq('search')
      feature['name'].should eq('Search')
      feature['state'].should eq('off')
      feature['description'].should eq('Disabled')
    end
  end

  describe "POST /flipper/features/:id/boolean" do
    before do
      feature = flipper[:some_thing]
      feature.enable
      params = {
        'value' => 'false',
      }
      post "/flipper/features/#{feature.name}/boolean", params
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end

    it "updates gate state" do
      flipper[:some_thing].state.should be(:off)
    end
  end

  describe "GET /flipper/images/logo.png" do
    before do
      get '/flipper/images/logo.png'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end
  end

  describe "GET /flipper/css/application.css" do
    before do
      get '/flipper/css/application.css'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end
  end

  context "Request method unsupported by action" do
    it "raises error" do
      expect {
        post '/flipper/images/logo.png'
      }.to raise_error(Flipper::UI::RequestMethodNotSupported)
    end
  end
end
