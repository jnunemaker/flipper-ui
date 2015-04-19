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

  describe "POST /features/:feature/non-existent-gate" do
    before do
      post "/features/search/non-existent-gate"
    end

    it "responds with redirect" do
      last_response.status.should be(302)
    end

    it "escapes error message" do
      last_response.headers["Location"].should eq("/features/search?error=%22non-existent-gate%22+gate+does+not+exist+therefore+it+cannot+be+updated.")
    end

    it "renders error in template" do
      follow_redirect!
      last_response.body.should match(/non-existent-gate.*gate does not exist/)
    end
  end

  describe "POST /features/:feature/boolean" do
    context "with enable" do
      before do
        flipper.disable :search
        post "features/search/boolean", "action" => "Enable"
      end

      it "enables the feature" do
        flipper.enabled?(:search).should be(true)
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search")
      end
    end

    context "with disable" do
      before do
        flipper.enable :search
        post "features/search/boolean", "action" => "Disable"
      end

      it "disables the feature" do
        flipper.enabled?(:search).should be(false)
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search")
      end
    end
  end

  describe "POST /features/:feature/percentage_of_time" do
    context "with valid value" do
      before do
        post "features/search/percentage_of_time", "value" => "24"
      end

      it "enables the feature" do
        flipper[:search].percentage_of_time_value.should be(24)
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search")
      end
    end

    context "with invalid value" do
      before do
        post "features/search/percentage_of_time", "value" => "555"
      end

      it "does not change value" do
        flipper[:search].percentage_of_time_value.should be(0)
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search?error=Invalid+percentage+of+time+value%3A+value+must+be+a+positive+number+less+than+or+equal+to+100%2C+but+was+555")
      end
    end
  end

  describe "POST /features/:feature/percentage_of_actors" do
    context "with valid value" do
      before do
        post "features/search/percentage_of_actors", "value" => "24"
      end

      it "enables the feature" do
        flipper[:search].percentage_of_actors_value.should be(24)
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search")
      end
    end

    context "with invalid value" do
      before do
        post "features/search/percentage_of_actors", "value" => "555"
      end

      it "does not change value" do
        flipper[:search].percentage_of_actors_value.should be(0)
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search?error=Invalid+percentage+of+time+value%3A+value+must+be+a+positive+number+less+than+or+equal+to+100%2C+but+was+555")
      end
    end
  end
end
