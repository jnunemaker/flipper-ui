require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'

describe Flipper::UI do
  include Rack::Test::Methods

  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }

  let(:flipper) {
    Flipper.new(adapter, :instrumenter => ActiveSupport::Notifications)
  }

  let(:app) {
    described_class.new(flipper)
  }

  describe "Initializing middleware lazily with a block" do
    let(:app) {
      described_class.new(lambda { flipper })
    }

    it "works" do
      get '/features'
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

  describe "GET /features" do
    before do
      flipper[:new_stats].enable
      flipper[:search].disable
      get '/features'
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

  describe "POST /features/:id/non_existent_gate_name" do
    before do
      feature = flipper[:some_thing]
      params = {
        'value' => 'something',
      }
      post "/features/#{feature.name}/non_existent_gate_name", params
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

  describe "POST /features/:id/boolean" do
    before do
      feature = flipper[:some_thing]
      feature.enable
      params = {
        'value' => 'false',
      }
      post "/features/#{feature.name}/boolean", params
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

  describe "POST /features/:id/percentage_of_actors" do
    context "valid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'value' => '5',
        }
        post "/features/#{feature.name}/percentage_of_actors", params
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
        gate_value(:some_thing, :percentage_of_actors).to_i.should be(5)
      end
    end

    context "invalid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'value' => '555',
        }
        post "/features/#{feature.name}/percentage_of_actors", params
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

  describe "POST /features/:id/percentage_of_random" do
    context "valid value" do
      before do
        feature = flipper[:some_thing]
        params = {
          'value' => '5',
        }
        post "/features/#{feature.name}/percentage_of_random", params
      end

      it "responds with 200" do
        last_response.status.should be(200)
      end

      it "responds with json" do
        result = json_response
        result.should be_instance_of(Hash)
        result['name'].should eq('percentage_of_random')
        result['key'].should eq('percentage_of_random')
        result['value'].should eq(5)
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
        post "/features/#{feature.name}/percentage_of_random", params
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

  describe "POST /features/:id/actor" do
    context "enable" do
      before do
        feature = flipper[:some_thing]
        params = {
          'operation' => 'enable',
          'value' => '11',
        }
        post "/features/#{feature.name}/actor", params
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
        post "/features/#{feature.name}/actor", params
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
        post "/features/#{feature.name}/actor", params
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

  describe "POST /features/:id/group" do
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
        post "/features/#{feature.name}/group", params
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
        post "/features/#{feature.name}/group", params
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
        post "/features/#{feature.name}/group", params
      end

      it "responds with 404" do
        last_response.status.should be(404)
      end
    end
  end

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

  context "Request method unsupported by action" do
    it "raises error" do
      expect {
        post '/images/logo.png'
      }.to raise_error(Flipper::UI::RequestMethodNotSupported)
    end
  end

  # Gets the adapter value for a given feature name and gate key.
  def gate_value(feature_name, gate_key)
    values = flipper.adapter.get(flipper[feature_name])
    values[gate_key]
  end
end
