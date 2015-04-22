require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'
require 'open-uri'

describe Flipper::UI::Actions::File do
  include Rack::Test::Methods

  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:app)     { Flipper::UI.app(flipper) }

  describe "GET /images/logo.png" do
    before do
      get '/images/logo.png'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end
  end

  describe "GET /css/application.css" do
    before do
      get '/css/application.css'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end
  end

  describe "GET /fonts/bootstrap/glyphicons-halflings-regular.eot" do
    before do
      get '/fonts/bootstrap/glyphicons-halflings-regular.eot'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end
  end

  describe "GET /octicons/octicons.eot" do
    before do
      get '/octicons/octicons.eot'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end
  end

  context "Request method unsupported by action" do
    it "raises error" do
      expect {
        post '/images/logo.png'
      }.to raise_error(Flipper::UI::RequestMethodNotSupported)
    end
  end
end
