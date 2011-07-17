require File.expand_path("../helper", __FILE__)

class ConfigurationTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  def setup
    @klass = Class.new(ActiveRecord::Base)
  end

  test "should set klass on initialization" do
    config = FriendlyId::Configuration.new @klass
    assert_equal @klass, config.klass
  end

  test "should set options on initialization if present" do
    config = FriendlyId::Configuration.new @klass, :base => "hello"
    assert_equal "hello", config.base
  end

  test "should raise error if passed unrecognized option" do
    assert_raises NoMethodError do
      FriendlyId::Configuration.new @klass, :foo => "bar"
    end
  end

end
