require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'
require 'flipper/ui/actor'

describe Flipper::UI do
  include Rack::Test::Methods

  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:app)     { described_class.app(flipper) }

  describe "Initializing middleware lazily with a block" do
    let(:app) { described_class.app(lambda { flipper }) }

    it "works" do
      get "/features"
      last_response.status.should be(200)
    end
  end
end
