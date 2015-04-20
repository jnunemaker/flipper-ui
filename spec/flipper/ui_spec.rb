require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'
require 'flipper/ui/actor'
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

  describe "GET /features/new" do
    before do
      get "/features/new"
    end

    it "responds with success" do
      last_response.status.should be(200)
    end

    it "renders template" do
      last_response.body.should include('<form action="/features" method="post">')
    end
  end

  describe "POST /features" do
    before do
      post "/features", "value" => "notifications_next"
    end

    it "adds feature" do
      flipper.features.map(&:key).should include("notifications_next")
    end

    it "redirects to features" do
      last_response.status.should be(302)
      last_response.headers["Location"].should eq("/features")
    end
  end

  describe "DELETE /features/:feature" do
    before do
      flipper.enable :search
      delete "/features/search"
    end

    it "removes feature" do
      flipper.features.map(&:key).should_not include("search")
    end

    it "redirects to features" do
      last_response.status.should be(302)
      last_response.headers["Location"].should eq("/features")
    end
  end

  describe "POST /features/:feature with _method=DELETE" do
    before do
      flipper.enable :search
      post "/features/search", "_method" => "DELETE"
    end

    it "removes feature" do
      flipper.features.map(&:key).should_not include("search")
    end

    it "redirects to features" do
      last_response.status.should be(302)
      last_response.headers["Location"].should eq("/features")
    end
  end

  describe "GET /features/:feature" do
    before do
      get "/features/search"
    end

    it "responds with success" do
      last_response.status.should be(200)
    end

    it "renders template" do
      last_response.body.should include("search")
      last_response.body.should include("Enable")
      last_response.body.should include("Disable")
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

  describe "GET /features/:feature/actors" do
    before do
      get "features/search/actors"
    end

    it "responds with success" do
      last_response.status.should be(200)
    end

    it "renders add new actor form" do
      last_response.body.should include("")
    end
  end

  describe "POST /features/:feature/actors" do
    context "enabling an actor" do
      before do
        post "features/search/actors", "value" => "User:6", "operation" => "enable"
      end

      it "adds item to members" do
        flipper[:search].actors_value.should include("User:6")
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search")
      end
    end

    context "disabling an actor" do
      before do
        flipper[:search].enable_actor Flipper::UI::Actor.new("User:6")
        post "features/search/actors", "value" => "User:6", "operation" => "disable"
      end

      it "removes item from members" do
        flipper[:search].actors_value.should_not include("User:6")
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search")
      end
    end

    context "for an invalid actor value" do
      before do
        post "features/search/actors", "value" => "", "operation" => "enable"
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search/actors?error=%22%22+is+not+a+valid+actor+value.")
      end
    end
  end

  describe "POST /features/:feature/groups" do
    before do
      Flipper.register(:admins) { |user| user.admin? }
    end

    after do
      Flipper.unregister_groups
    end

    context "enabling a group" do
      before do
        post "features/search/groups", "value" => "admins", "operation" => "enable"
      end

      it "adds item to members" do
        flipper[:search].groups_value.should include("admins")
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search")
      end
    end

    context "disabling a group" do
      before do
        flipper[:search].enable_group :admins
        post "features/search/groups", "value" => "admins", "operation" => "disable"
      end

      it "removes item from members" do
        flipper[:search].groups_value.should_not include("admins")
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search")
      end
    end

    context "for an unregistered group" do
      before do
        post "features/search/groups", "value" => "not_here", "operation" => "enable"
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search/groups?error=The+group+named+%22not_here%22+has+not+been+registered.")
      end
    end
  end
end
