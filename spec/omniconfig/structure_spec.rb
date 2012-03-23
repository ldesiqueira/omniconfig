require File.expand_path("../../setup", __FILE__)
require "omniconfig"

describe OmniConfig::Structure do
  let(:instance) { described_class.new }

  it "should be able to define members using a hash to initialize" do
    instance = described_class.new("foo" => "bar")
    instance.members["foo"].should == "bar"
  end

  it "should be able to define new members" do
    expect { instance.define("foo", "bar") }.to_not raise_error

    instance.members.should have_key("foo")
    instance.members["foo"].should == "bar"
  end

  it "should force all member keys to be strings" do
    instance.define(:foo, "bar")
    instance.members.should_not have_key(:foo)
    instance.members["foo"].should == "bar"
  end

  describe "value parsing" do
    it "should raise a TypeError if not a hash" do
      expect { instance.value(7) }.to raise_error(OmniConfig::TypeError)
    end

    it "should work with a valid structure" do
      instance.define("foo", OmniConfig::Type::Any)
      instance.define("bar", OmniConfig::Type::Any)

      original = { "foo" => 1, "bar" => "2", "baz" => 3 }
      expected = { "foo" => 1, "bar" => "2" }
      instance.value(original).should == expected
    end
  end
end
