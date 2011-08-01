require File.expand_path("../helper", __FILE__)

class Novelist < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged
end

class Novel < ActiveRecord::Base
  extend FriendlyId
  belongs_to :novelist
  friendly_id :name, :use => :scoped, :scope => :novelist
end

class ScopedTest < MiniTest::Unit::TestCase

  include FriendlyId::Test
  include FriendlyId::Test::Shared

  def model_class
    Novel
  end

  test "should detect scope column from belongs_to relation" do
    assert_equal "novelist_id", Novel.friendly_id_config.scope_column
  end

  test "should detect scope column from explicit column name" do
    model_class = Class.new(ActiveRecord::Base)
    model_class.extend FriendlyId
    model_class.friendly_id :empty, :use => :scoped, :scope => :dummy
    assert_equal "dummy", model_class.friendly_id_config.scope_column
  end

  test "should allow duplicate slugs outside scope" do
    transaction do
      novel1 = Novel.create! :name => "a", :novelist => Novelist.create!(:name => "a")
      novel2 = Novel.create! :name => "a", :novelist => Novelist.create!(:name => "b")
      assert_equal novel1.friendly_id, novel2.friendly_id
    end
  end

  test "should not allow duplicate slugs inside scope" do
    with_instance_of Novelist do |novelist|
      novel1 = Novel.create! :name => "a", :novelist => novelist
      novel2 = Novel.create! :name => "a", :novelist => novelist
      assert novel1.friendly_id != novel2.friendly_id
    end
  end

  test "should raise error if used with history" do
    model_class = Class.new(ActiveRecord::Base)
    model_class.extend FriendlyId
    assert_raises RuntimeError do
      model_class.friendly_id :name, :use => [:scoped, :history]
    end
  end
end