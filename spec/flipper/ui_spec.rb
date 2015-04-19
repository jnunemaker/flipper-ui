require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'
require 'open-uri'

describe Flipper::UI do
  include Rack::Test::Methods

  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }

  let(:flipper) {
    Flipper.new(adapter)
  }

  let(:app) { described_class.app(flipper) }

  describe "Initializing middleware lazily with a block" do
    let(:app) { described_class.app(lambda { flipper }) }

    it "works" do
      get "/features"
      last_response.status.should be(200)
    end
  end

  describe "GET /" do
    before do
      flipper[:stats].enable
      flipper[:search].enable
      get "/"
    end

    it "responds with redirect" do
      last_response.status.should be(302)
      last_response.headers["Location"].should eq("/features")
    end
  end

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

  describe "GET /features/:feature" do
    before do
      flipper[:search].enable
      get "/features/search"
    end

    it "responds with success" do
      last_response.status.should be(200)
    end

    it "renders template" do
      last_response.body.should include("search")
      last_response.body.should include("Boolean")
      last_response.body.should include("Actors")
      last_response.body.should include("Groups")
      last_response.body.should include("Percentage of Time")
      last_response.body.should include("Percentage of Actors")
    end
  end
end
