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
end
