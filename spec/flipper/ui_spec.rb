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
      get '/'
      last_response.status.should be(200)
    end
  end

  describe "GET /" do
    before do
      flipper[:stats].enable
      flipper[:search].enable
      get '/'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end

    it "renders view" do
      last_response.body.should match(/Flipper/)
    end
  end
end
