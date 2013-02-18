require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'

describe Flipper::UI::Middleware do
  include Rack::Test::Methods

  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }

  let(:flipper) {
    Flipper.new(adapter, :instrumenter => ActiveSupport::Notifications)
  }

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

  def gate_value(feature_name, gate_key)
    values = flipper.adapter.get(flipper[feature_name])
    values[gate_key]
  end

  describe "GET /flipper" do
    before do
      flipper[:stats].enable
      flipper[:search].enable
      get '/flipper'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end

    it "renders view" do
      last_response.body.should match(/Flipper/)
    end
  end

  describe "GET /flipper/features" do
    before do
      flipper[:new_stats].enable
      flipper[:search].disable
      get '/flipper/features'
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end

    it "responds with content type of json" do
      last_response.content_type.should eq('application/json')
    end

    it "renders view" do
      features = json_response
      features.should be_instance_of(Array)

      feature = features[0]
      feature['id'].should eq('new_stats')
      feature['name'].should eq('New Stats')
      feature['state'].should eq('on')
      feature['description'].should eq('Enabled')
      feature['gates'].first.should eq({
        'name' => 'boolean',
        'key' => 'boolean',
        'value' => true,
      })

      feature = features[1]
      feature['id'].should eq('search')
      feature['name'].should eq('Search')
      feature['state'].should eq('off')
      feature['description'].should eq('Disabled')
      feature['gates'].first.should eq({
        'name' => 'boolean',
        'key' => 'boolean',
        'value' => false,
      })
    end
  end

  describe "POST /flipper/features/:id/non_existent_gate_name" do
    before do
      feature = flipper[:some_thing]
      params = {
        'value' => 'something',
      }
      post "/flipper/features/#{feature.name}/non_existent_gate_name", params
    end

    it "responds with 404" do
      last_response.status.should be(404)
    end

    it "includes status and message" do
      result = json_response
      result['status'].should eq('error')
      result['message'].should eq('I have no clue how to update the gate named "non_existent_gate_name".')
    end
  end

  describe "POST /flipper/features/:id/boolean" do
    before do
      feature = flipper[:some_thing]
      feature.enable
      params = {
        'value' => 'false',
      }
      post "/flipper/features/#{feature.name}/boolean", params
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end

    it "updates gate state" do
      flipper[:some_thing].state.should be(:off)
    end
  end

  describe "POST /flipper/features/:id/percentage_of_actors" do
    context "valid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'value' => '5',
        }
        post "/flipper/features/#{feature.name}/percentage_of_actors", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "updates gate state" do
        gate_value(:some_thing, :percentage_of_actors).to_i.should be(5)
      end
    end

    context "invalid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'value' => '555',
        }
        post "/flipper/features/#{feature.name}/percentage_of_actors", params
      end

      it "responds with 422" do
        last_response.status.should be(422)
      end

      it "includes status and message in response" do
        result = json_response
        result['status'].should eq('error')
        result['message'].should eq('value must be a positive number less than or equal to 100, but was 555')
      end
    end
  end

  describe "POST /flipper/features/:id/percentage_of_random" do
    context "valid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'value' => '5',
        }
        post "/flipper/features/#{feature.name}/percentage_of_random", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "updates gate state" do
        gate_value(:some_thing, :percentage_of_random).to_i.should be(5)
      end
    end

    context "invalid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'value' => '555',
        }
        post "/flipper/features/#{feature.name}/percentage_of_random", params
      end

      it "responds with 422" do
        last_response.status.should be(422)
      end

      it "includes status and message in response" do
        result = json_response
        result['status'].should eq('error')
        result['message'].should eq('value must be a positive number less than or equal to 100, but was 555')
      end
    end
  end

  describe "POST /flipper/features/:id/actor" do
    context "enable" do
      before do
        feature = flipper[:some_thing]
        params = {
          'operation' => 'enable',
          'value' => '11',
        }
        post "/flipper/features/#{feature.name}/actor", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "updates gate state" do
        gate_value(:some_thing, :actors).should include('11')
      end
    end

    context "disable" do
      before do
        feature = flipper[:some_thing]
        feature.enable Struct.new(:flipper_id).new('11')
        params = {
          'operation' => 'disable',
          'value' => '11',
        }
        post "/flipper/features/#{feature.name}/actor", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "updates gate state" do
        gate_value(:some_thing, :actors).should_not include('11')
      end
    end

    context "invalid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'operation' => 'enable',
          'value' => '',
        }
        post "/flipper/features/#{feature.name}/actor", params
      end

      it "responds with 422" do
        last_response.status.should be(422)
      end

      it "updates gate state" do
        result = json_response
        result['status'].should eq('error')
        result['message'].should eq('"" is not a valid actor value.')
      end
    end
  end

  describe "POST /flipper/features/:id/group" do
    before do
      Flipper.register(:admins) { |user| user.admin? }
    end

    after do
      Flipper.groups = nil
    end

    context "enable" do
      before do
        feature = flipper[:some_thing]
        params = {
          'operation' => 'enable',
          'value' => 'admins',
        }
        post "/flipper/features/#{feature.name}/group", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "updates gate state" do
        gate_value(:some_thing, :groups).should include('admins')
      end
    end

    context "disable" do
      before do
        feature = flipper[:some_thing]
        feature.enable flipper.group(:admins)
        params = {
          'operation' => 'disable',
          'value' => 'admins',
        }
        post "/flipper/features/#{feature.name}/group", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "updates gate state" do
        gate_value(:some_thing, :groups).should_not include('admins')
      end
    end

    context "when group is not found" do
      before do
        feature = flipper[:some_thing]
        params = {
          'operation' => 'enable',
          'value' => 'not_here',
        }
        post "/flipper/features/#{feature.name}/group", params
      end

      it "responds with 404" do
        last_response.status.should be(404)
      end
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

  context "Request method unsupported by action" do
    it "raises error" do
      expect {
        post '/flipper/images/logo.png'
      }.to raise_error(Flipper::UI::RequestMethodNotSupported)
    end
  end
end
