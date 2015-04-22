require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'

describe Flipper::UI do
  include Rack::Test::Methods

  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:app)     { described_class.app(flipper) }

  describe "Initializing middleware with flipper instance" do
    let(:app) { described_class.app(flipper) }

    it "works" do
      flipper.enable :some_great_feature
      get "/features"
      last_response.status.should be(200)
      last_response.body.should include("some_great_feature")
    end
  end

  describe "Initializing middleware lazily with a block" do
    let(:app) { described_class.app(lambda { flipper }) }

    it "works" do
      flipper.enable :some_great_feature
      get "/features"
      last_response.status.should be(200)
      last_response.body.should include("some_great_feature")
    end
  end
end
