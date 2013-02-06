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

  describe "#html_id" do
    it "dasherizes underscores" do
      subject.html_id.should eq('some-awesome-feature')
    end
  end

  describe "#pretty_name" do
    it "capitalizes each word separated by underscores" do
      subject.pretty_name.should eq('Some Awesome Feature')
    end
  end
end
