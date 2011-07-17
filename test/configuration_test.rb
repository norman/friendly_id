require File.expand_path("../helper", __FILE__)

class ConfigurationTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  test "should set klass on initialization" do
    config = FriendlyId::Configuration.new TrueClass
    assert_equal TrueClass, config.klass
  end

  test "should set options on initialization if present" do
    config = FriendlyId::Configuration.new TrueClass, :base => "hello"
    assert_equal "hello", config.base
  end

  test "should raise error if passed unrecognized option" do
    assert_raises ArgumentError do
      FriendlyId::Configuration.new TrueClass, :foo => "bar"
    end
  end

end
