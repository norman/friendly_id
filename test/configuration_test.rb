require File.expand_path("../helper", __FILE__)

class ConfigurationTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  def setup
    @model_class = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
    end
  end

  test "should set model class on initialization" do
    config = FriendlyId::Configuration.new @model_class
    assert_equal @model_class, config.model_class
  end

  test "should set options on initialization if present" do
    config = FriendlyId::Configuration.new @model_class, :base => "hello"
    assert_equal "hello", config.base
  end

  test "should raise error if passed unrecognized option" do
    assert_raises NoMethodError do
      FriendlyId::Configuration.new @model_class, :foo => "bar"
    end
  end

end
