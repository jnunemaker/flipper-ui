require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'
require 'flipper/ui/actor'

describe Flipper::UI::Actions::Index do
  include Rack::Test::Methods

  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:app)     { Flipper::UI.app(flipper) }

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
end
