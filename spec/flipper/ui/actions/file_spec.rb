require 'helper'

describe Flipper::UI::Actions::File do
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
end
