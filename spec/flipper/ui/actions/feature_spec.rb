require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'
require 'flipper/ui/actor'

describe Flipper::UI::Actions::Feature do
  include Rack::Test::Methods

  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:app)     { Flipper::UI.app(flipper) }

  describe "DELETE /features/:feature" do
    before do
      flipper.enable :search
      delete "/features/search"
    end

    it "removes feature" do
      flipper.features.map(&:key).should_not include("search")
    end

    it "redirects to features" do
      last_response.status.should be(302)
      last_response.headers["Location"].should eq("/features")
    end
  end

  describe "POST /features/:feature with _method=DELETE" do
    before do
      flipper.enable :search
      post "/features/search", "_method" => "DELETE"
    end

    it "removes feature" do
      flipper.features.map(&:key).should_not include("search")
    end

    it "redirects to features" do
      last_response.status.should be(302)
      last_response.headers["Location"].should eq("/features")
    end
  end

  describe "GET /features/:feature" do
    before do
      get "/features/search"
    end

    it "responds with success" do
      last_response.status.should be(200)
    end

    it "renders template" do
      last_response.body.should include("search")
      last_response.body.should include("Enable")
      last_response.body.should include("Disable")
      last_response.body.should include("Actors")
      last_response.body.should include("Groups")
      last_response.body.should include("Percentage of Time")
      last_response.body.should include("Percentage of Actors")
    end
  end
end
