require File.expand_path("../helper.rb", __FILE__)

class Manual < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :history
end

class HistoryTest < MiniTest::Unit::TestCase

  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core

  def model_class
    Manual
  end

  test "should insert record in slugs table on create" do
    with_instance_of(model_class) {|record| assert !record.slugs.empty?}
  end

  test "should not create new slug record if friendly_id is not changed" do
    with_instance_of(model_class) do |record|
      record.active = true
      record.save!
      assert_equal 1, FriendlyId::Slug.count
    end
  end

  test "should create new slug record when friendly_id changes" do
    with_instance_of(model_class) do |record|
      record.name = record.name + "b"
      record.save!
      assert_equal 2, FriendlyId::Slug.count
    end
  end

  test "should be findable by old slugs" do
    with_instance_of(model_class) do |record|
      old_friendly_id = record.friendly_id
      record.name = record.name + "b"
      record.save!
      assert found = model_class.find_by_friendly_id(old_friendly_id)
      assert !found.readonly?
    end
  end

  test "should raise error if used with scoped" do
    model_class = Class.new(ActiveRecord::Base)
    model_class.extend FriendlyId
    assert_raises RuntimeError do
      model_class.friendly_id :name, :use => [:history, :scoped]
    end
  end

end
