require File.expand_path("../helper.rb", __FILE__)

class Manual < ActiveRecord::Base
  extend FriendlyId
  include FriendlyId::History
  has_friendly_id :name
end

class HistoryTest < MiniTest::Unit::TestCase

  include FriendlyId::Test
  include FriendlyId::Test::Shared

  def klass
    Manual
  end

  test "should insert record in slugs table on create" do
    with_instance_of(klass) {|record| assert !record.friendly_id_slugs.empty?}
  end

  test "should not create new slug record if friendly_id is not changed" do
    with_instance_of(klass) do |record|
      record.active = true
      record.save!
      assert_equal 1, FriendlyIdSlug.count
    end
  end

  test "should create new slug record when friendly_id changes" do
    with_instance_of(klass) do |record|
      record.name = record.name + "b"
      record.save!
      assert_equal 2, FriendlyIdSlug.count
    end
  end

  test "should be findable by old slugs" do
    with_instance_of(klass) do |record|
      old_friendly_id = record.friendly_id
      record.name = record.name + "b"
      record.save!
      assert found = klass.find_by_friendly_id(old_friendly_id)
      assert !found.readonly?
    end
  end
end
