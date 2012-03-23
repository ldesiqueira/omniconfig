require File.expand_path("../../setup", __FILE__)
require "omniconfig"

describe OmniConfig::Config do
  let(:instance) { described_class.new(structure) }
  let(:structure) { OmniConfig::Structure.new }

  let(:smallest_number_type) {
    Class.new do
      def merge(old, new)
        [old, new].min
      end
    end
  }

  it "should load basic values" do
    config = { "key" => "value" }
    structure.define("key", OmniConfig::Type::String)
    instance.add_loader(OmniConfig::Loader::Hash.new(config))

    result = instance.load
    result["key"].should == "value"
  end

  it "should mark settings as UNSET if they aren't set" do
    structure.define("key", OmniConfig::Type::String)
    instance.add_loader(OmniConfig::Loader::Hash.new({}))

    result = instance.load
    result["key"].should eql(OmniConfig::UNSET_VALUE)
   end

  it "should prefer values loaded later by default" do
    structure.define("key", OmniConfig::Type::String)
    instance.add_loader(OmniConfig::Loader::Hash.new({ "key" => "foo" }))
    instance.add_loader(OmniConfig::Loader::Hash.new({ "key" => "bar" }))

    result = instance.load
    result["key"].should == "bar"
  end

  it "should merge values if the type supports it" do
    structure.define("key", smallest_number_type)
    instance.add_loader(OmniConfig::Loader::Hash.new({ "key" => 3 }))
    instance.add_loader(OmniConfig::Loader::Hash.new({ "key" => 2 }))
    instance.add_loader(OmniConfig::Loader::Hash.new({ "key" => 5 }))

    result = instance.load
    result["key"].should == 2
  end
end