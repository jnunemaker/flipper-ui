require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'
require 'flipper/ui/actor'

describe Flipper::UI::Actions::Features do
  include Rack::Test::Methods

  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:app)     { Flipper::UI.app(flipper) }

  describe "GET /features" do
    before do
      flipper[:stats].enable
      flipper[:search].enable
      get "/features"
    end

    it "responds with success" do
      last_response.status.should be(200)
    end

    it "renders template" do
      last_response.body.should include("stats")
      last_response.body.should include("search")
    end
  end

  describe "POST /features" do
    before do
      post "/features", "value" => "notifications_next"
    end

    it "adds feature" do
      flipper.features.map(&:key).should include("notifications_next")
    end

    it "redirects to features" do
      last_response.status.should be(302)
      last_response.headers["Location"].should eq("/features")
    end
  end
end
