# encoding: utf-8
require File.expand_path("../helper", __FILE__)

require File.expand_path("../helper.rb", __FILE__)

class ObjectUtilsTest < MiniTest::Unit::TestCase

  include FriendlyId::Test
  include FriendlyId::Test::Shared

  def klass
    Novel
  end

  test "should detect scope column from belongs_to relation" do
    assert_equal "novelist_id", Novel.friendly_id_config.scope_column
  end

  test "should detect scope column from explicit column name" do
    klass = Class.new(ActiveRecord::Base)
    klass.has_friendly_id :empty, :scope => :dummy
    assert_equal "dummy", klass.friendly_id_config.scope_column
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

end