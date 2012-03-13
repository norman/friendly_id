require "helper"

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
    with_instance_of(model_class) {|record| assert record.slugs.any?}
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
      begin
        assert model_class.find(old_friendly_id)
        assert model_class.exists?(old_friendly_id), "should exist? by old id"
      rescue ActiveRecord::RecordNotFound
        flunk "Could not find record by old id"
      end
    end
  end

  test "should create slug records on each change" do
    transaction do
      record = model_class.create! :name => "hello"
      assert_equal 1, FriendlyId::Slug.count
      record = model_class.find("hello")
      record.name = "hello again"
      record.save!
      assert_equal 2, FriendlyId::Slug.count
    end
  end

  test "should not be read only when found by old slug" do
    with_instance_of(model_class) do |record|
      old_friendly_id = record.friendly_id
      record.name = record.name + "b"
      record.save!
      assert !model_class.find(old_friendly_id).readonly?
    end
  end

  test "should create correct sequence numbers even when some conflicted slugs have changed" do
    transaction do
      record1 = model_class.create! :name => 'hello'
      record2 = model_class.create! :name => 'hello!'
      record2.update_attributes :name => 'goodbye'
      record3 = model_class.create! :name => 'hello!'
      assert_equal 'hello--3', record3.slug
    end
  end


  test "should raise error if used with scoped" do
    model_class = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      extend FriendlyId
    end
    assert_raises RuntimeError do
      model_class.friendly_id :name, :use => [:history, :scoped]
    end
  end

  test "should handle renames" do
    with_instance_of(model_class) do |record|
      record.name = 'x'
      assert record.save
      record.name = 'y'
      assert record.save
      record.name = 'x'
      assert record.save
    end
  end

  test "should not create new slugs that match old slugs" do
    transaction do
      first_record = model_class.create! :name => "foo"
      first_record.name = "bar"
      first_record.save!
      second_record = model_class.create! :name => "foo"
      assert second_record.slug != "foo"
      assert second_record.slug == "foo--2"
    end
  end

  test 'should increment the sequence by one for each historic slug' do
    transaction do
      previous_record = model_class.create! :name => "foo"
      first_record = model_class.create! :name => 'another'
      second_record = model_class.create! :name => 'another'
      assert second_record.slug == "another--2"
    end
  end

  test 'should not fail when updating historic slugs' do
    transaction do
      first_record = model_class.create! :name => "foo"
      second_record = model_class.create! :name => 'another'

      second_record.update_attributes :name => 'foo'
      assert second_record.slug == "foo--2"
      first_record.update_attributes :name => 'another'
      assert first_record.slug == "another--2"
    end
  end

end

class HistoryTestWithSti < HistoryTest
  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => [:slugged, :history]
  end

  class Editorialist < Journalist
  end

  def model_class
    Editorialist
  end
end