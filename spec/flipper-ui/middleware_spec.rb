require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'

describe Flipper::UI::Middleware do
  include Rack::Test::Methods

  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }
  let(:flipper) { Flipper.new(adapter) }

  def app
    @app ||= begin
      middleware = described_class
      instance = flipper

      Rack::Builder.new do
        use middleware, instance

        map "/" do
          run lambda {|env| [404, {}, []] }
        end
      end.to_app
    end
  end

  describe "GET /flipper" do
    before do
      get '/flipper'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end

    it "renders view" do
      last_response.body.should match(/Flipper/)
    end
  end

  describe "GET /flipper/images/logo.png" do
    before do
      get '/flipper/images/logo.png'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end
  end

  describe "GET /flipper/css/application.css" do
    before do
      get '/flipper/css/application.css'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end
  end
end
