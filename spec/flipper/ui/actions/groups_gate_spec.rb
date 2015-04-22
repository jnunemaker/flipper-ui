require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'
require 'flipper/ui/actor'

describe Flipper::UI::Actions::GroupsGate do
  include Rack::Test::Methods

  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }
  let(:app)     { Flipper::UI.app(flipper) }

  describe "GET /features/:feature/groups" do
    before do
      Flipper.register(:admins) { |user| user.admin? }
      get "features/search/groups"
    end

    after do
      Flipper.unregister_groups
    end

    it "responds with success" do
      last_response.status.should be(200)
    end

    it "renders add new group form" do
      last_response.body.should include('<form action="/features/search/groups" method="post">')
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
