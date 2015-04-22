require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'
require 'flipper/ui/actor'

describe Flipper::UI::Actions::Gate do
  include Rack::Test::Methods

  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:app)     { Flipper::UI.app(flipper) }

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
