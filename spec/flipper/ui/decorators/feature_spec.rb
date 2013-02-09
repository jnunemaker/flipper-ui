require 'helper'
require 'flipper/adapters/memory'

describe Flipper::UI::Decorators::Feature do
  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }
  let(:flipper) { Flipper.new(adapter) }
  let(:feature) { flipper[:some_awesome_feature] }

  subject {
    described_class.new(feature)
  }

  it "initializes with feature" do
    subject.feature.should be(feature)
  end

  describe "#pretty_name" do
    it "capitalizes each word separated by underscores" do
      subject.pretty_name.should eq('Some Awesome Feature')
    end
  end

  describe "#as_json" do
    before do
      @result = subject.as_json
    end

    it "returns Hash" do
      @result.should be_instance_of(Hash)
    end

    it "includes id" do
      @result['id'].should eq('some_awesome_feature')
    end

    it "includes pretty name" do
      @result['name'].should eq('Some Awesome Feature')
    end

    it "includes state" do
      @result['state'].should eq('off')
    end

    it "includes description" do
      @result['description'].should eq('Disabled')
    end
  end
end
