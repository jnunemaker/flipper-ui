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

  describe "GET /api/features" do
    before do
      flipper[:new_stats].enable
      flipper[:search].disable
      get '/api/features'
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
        'key' => 'boolean',
        'name' => 'boolean',
        'value' => true,
      })

      feature = features[1]
      feature['id'].should eq('search')
      feature['name'].should eq('Search')
      feature['state'].should eq('off')
      feature['description'].should eq('Disabled')
      feature['gates'].first.should eq({
        'key' => 'boolean',
        'name' => 'boolean',
        'value' => false,
      })
    end
  end

  describe "POST /api/features" do
    context "for good value" do
      before do
        params = {
          'value' => 'search',
        }
        post "/api/features", params
      end

      it "responds with 201" do
        last_response.status.should be(201)
      end

      it "responds with json" do
        result = json_response
        result.should be_instance_of(Hash)
        result['id'].should eq('search')
        result['name'].should eq('Search')
        result['state'].should eq('off')
        result['description'].should eq('Disabled')
        result['gates'].should be_instance_of(Array)
        result['gates'].size.should be(5)
      end
    end

    context "with blank feature name" do
      before do
        params = {
          'value' => '',
        }
        post "/api/features", params
      end

      it "responds with 422" do
        last_response.status.should be(422)
      end

      it "includes status and message" do
        result = json_response
        result['status'].should eq('error')
        result['message'].should eq('"" is not a valid feature name.')
      end
    end

    context "with already existing feature name" do
      before do
        flipper.enable :search
        params = {
          "value" => "search",
        }
        post "/api/features", params
      end

      it "responds with 422" do
        last_response.status.should be(422)
      end

      it "includes status and message" do
        result = json_response
        result['status'].should eq("error")
        result['message'].should eq("\"search\" already exists.")
      end
    end
  end

  describe "POST /api/features/:id/non_existent_gate_name" do
    before do
      feature = flipper[:some_thing]
      params = {
        'value' => 'something',
      }
      post "/api/features/#{feature.name}/non_existent_gate_name", params
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

  describe "POST /api/features/:id/boolean" do
    before do
      feature = flipper[:some_thing]
      feature.enable
      params = {
        'value' => 'false',
      }
      post "/api/features/#{feature.name}/boolean", params
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end

    it "responds with json" do
      result = json_response
      result.should be_instance_of(Hash)
      result['name'].should eq('boolean')
      result['key'].should eq('boolean')
      result['value'].should eq(false)
    end

    it "updates gate state" do
      flipper[:some_thing].state.should be(:off)
    end
  end

  describe "POST /api/features/:id/boolean for values that are URI encoded" do
    before do
      feature = flipper["feature:v1"]
      feature.enable
      params = {
        'value' => 'false',
      }
      feature_encoded_name = URI.encode_www_form_component(feature.name)
      post "/api/features/#{feature_encoded_name}/boolean", params
    end

    it "responds with 200" do
      last_response.status.should be(200)
    end

    it "responds with json" do
      result = json_response
      result.should be_instance_of(Hash)
      result['name'].should eq('boolean')
      result['key'].should eq('boolean')
      result['value'].should eq(false)
    end

    it "updates gate state" do
      flipper["feature:v1"].state.should be(:off)
    end
  end

  describe "POST /api/features/:id/percentage_of_actors" do
    context "valid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'value' => '5',
        }
        post "/api/features/#{feature.name}/percentage_of_actors", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "responds with json" do
        result = json_response
        result.should be_instance_of(Hash)
        result['name'].should eq('percentage_of_actors')
        result['key'].should eq('percentage_of_actors')
        result['value'].should eq(5)
      end

      it "updates gate state" do
        flipper[:some_thing].percentage_of_actors_value.should be(5)
      end
    end

    context "invalid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'value' => '555',
        }
        post "/api/features/#{feature.name}/percentage_of_actors", params
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

  describe "POST /api/features/:id/percentage_of_time" do
    context "valid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'value' => '5',
        }
        post "/api/features/#{feature.name}/percentage_of_time", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "responds with json" do
        result = json_response
        result.should be_instance_of(Hash)
        result['name'].should eq('percentage_of_time')
        result['key'].should eq('percentage_of_time')
        result['value'].should eq(5)
      end

      it "updates gate state" do
        flipper[:some_thing].percentage_of_time_value.should be(5)
      end
    end

    context "invalid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'value' => '555',
        }
        post "/api/features/#{feature.name}/percentage_of_time", params
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

  describe "POST /api/features/:id/actor" do
    context "enable" do
      before do
        feature = flipper[:some_thing]
        params = {
          'operation' => 'enable',
          'value' => '11',
        }
        post "/api/features/#{feature.name}/actor", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "responds with json" do
        result = json_response
        result.should be_instance_of(Hash)
        result['name'].should eq('actor')
        result['key'].should eq('actors')
        result['value'].should eq(['11'])
      end

      it "updates gate state" do
        flipper[:some_thing].actors_value.should include('11')
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
        post "/api/features/#{feature.name}/actor", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "responds with json" do
        result = json_response
        result.should be_instance_of(Hash)
        result['name'].should eq('actor')
        result['key'].should eq('actors')
        result['value'].should eq([])
      end

      it "updates gate state" do
        flipper[:some_thing].actors_value.should_not include('11')
      end
    end

    context "invalid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'operation' => 'enable',
          'value' => '',
        }
        post "/api/features/#{feature.name}/actor", params
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

  describe "POST /api/features/:id/group" do
    before do
      Flipper.register(:admins) { |user| user.admin? }
    end

    after do
      Flipper.unregister_groups
    end

    context "enable" do
      before do
        feature = flipper[:some_thing]
        params = {
          'operation' => 'enable',
          'value' => 'admins',
        }
        post "/api/features/#{feature.name}/group", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "responds with json" do
        result = json_response
        result.should be_instance_of(Hash)
        result['name'].should eq('group')
        result['key'].should eq('groups')
        result['value'].should eq(['admins'])
      end

      it "updates gate state" do
        flipper[:some_thing].groups_value.should include('admins')
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
        post "/api/features/#{feature.name}/group", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "responds with json" do
        result = json_response
        result.should be_instance_of(Hash)
        result['name'].should eq('group')
        result['key'].should eq('groups')
        result['value'].should eq([])
      end

      it "updates gate state" do
        flipper[:some_thing].groups_value.should_not include('admins')
      end
    end

    context "when group is not found" do
      before do
        feature = flipper[:some_thing]
        params = {
          'operation' => 'enable',
          'value' => 'not_here',
        }
        post "/api/features/#{feature.name}/group", params
      end

      it "responds with 404" do
        last_response.status.should be(404)
      end
    end

    context "when group is empty" do
      before do
        feature = flipper[:some_thing]
        params = {
          'operation' => 'enable',
          'value' => '',
        }
        post "/api/features/#{feature.name}/group", params
      end

      it "responds with 422" do
        last_response.status.should be(422)
      end

      it "has message in body" do
        hash = JSON.load(last_response.body)
        hash["status"].should eq("error")
        hash["message"].should eq("Group name is required.")
      end
    end
  end
end
