require 'helper'
require 'flipper/adapters/memory'
require 'flipper/ui/decorators/gate'

describe Flipper::UI::Decorators::Gate do
  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }
  let(:flipper) { Flipper.new(adapter) }
  let(:feature) { flipper[:some_awesome_feature] }
  let(:gate) { feature.gates.first }

  subject {
    described_class.new(gate)
  }

  it "initializes with gate" do
    subject.gate.should be(gate)
  end

  describe "#as_json" do
    before do
      @result = subject.as_json
    end

    it "returns Hash" do
      @result.should be_instance_of(Hash)
    end

    it "includes key" do
      @result['key'].should eq('boolean')
    end

    it "includes pretty name" do
      @result['name'].should eq('boolean')
    end

    it "includes value" do
      @result['value'].should eq(false)
    end
  end
end
