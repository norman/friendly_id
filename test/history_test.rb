require "helper"

class Manual < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => [:slugged, :history]
end

class HistoryTest < Minitest::Test

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
      record.slug = nil
      record.save!
      assert_equal 2, FriendlyId::Slug.count
    end
  end

  test "should be findable by old slugs" do
    with_instance_of(model_class) do |record|
      old_friendly_id = record.friendly_id
      record.name = record.name + "b"
      record.slug = nil
      record.save!
      begin
        assert model_class.friendly.find(old_friendly_id)
        assert model_class.friendly.exists?(old_friendly_id), "should exist? by old id"
      rescue ActiveRecord::RecordNotFound
        flunk "Could not find record by old id"
      end
    end
  end

  test "should create slug records on each change" do
    transaction do
      record = model_class.create! :name => "hello"
      assert_equal 1, FriendlyId::Slug.count
      record = model_class.friendly.find("hello")
      record.name = "hello again"
      record.slug = nil
      record.save!
      assert_equal 2, FriendlyId::Slug.count
    end
  end

  test "should not be read only when found by slug" do
    with_instance_of(model_class) do |record|
      refute model_class.friendly.find(record.friendly_id).readonly?
      assert record.update_attribute :name, 'foo'
      assert record.update_attributes name: 'foo'
    end
  end

  test "should not be read only when found by old slug" do
    with_instance_of(model_class) do |record|
      old_friendly_id = record.friendly_id
      record.name = record.name + "b"
      record.save!
      assert !model_class.friendly.find(old_friendly_id).readonly?
    end
  end

  test "should handle renames" do
    with_instance_of(model_class) do |record|
      record.name = 'x'
      record.slug = nil
      assert record.save
      record.name = 'y'
      record.slug = nil
      assert record.save
      record.name = 'x'
      record.slug = nil
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
      assert_match(/foo-.+/, second_record.slug)
    end
  end

  test 'should not fail when updating historic slugs' do
    transaction do
      first_record = model_class.create! :name => "foo"
      second_record = model_class.create! :name => 'another'

      second_record.update_attributes :name => 'foo', :slug => nil
      assert_match(/foo-.*/, second_record.slug)

      first_record.update_attributes :name => 'another', :slug => nil
      assert_match(/another-.*/, first_record.slug)
    end
  end

  test 'should name table according to prefix and suffix' do
    transaction do
      begin
        prefix = "prefix_"
        without_prefix = FriendlyId::Slug.table_name
        ActiveRecord::Base.table_name_prefix = prefix
        FriendlyId::Slug.reset_table_name
        assert_equal prefix + without_prefix, FriendlyId::Slug.table_name
      ensure
        ActiveRecord::Base.table_name_prefix = ""
        FriendlyId::Slug.table_name = without_prefix
      end
    end
  end
end

class HistoryTestWithAutomaticSlugRegeneration < HistoryTest
  class Manual < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => [:slugged, :history]

    def should_generate_new_friendly_id?
      slug.blank? or name_changed?
    end
  end

  def model_class
    Manual
  end

  test 'should allow reversion back to a previously used slug' do
    with_instance_of(model_class, name: 'foo') do |record|
      record.name = 'bar'
      record.save!
      assert_equal 'bar', record.friendly_id
      record.name = 'foo'
      record.save!
      assert_equal 'foo', record.friendly_id
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

class HistoryTestWithFriendlyFinders < HistoryTest
  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => [:slugged, :finders, :history]
  end

  class Restaurant < ActiveRecord::Base
    extend FriendlyId
    belongs_to :city
    friendly_id :name, :use => [:slugged, :history, :finders]
  end


  test "should be findable by old slugs" do
    [Journalist, Restaurant].each do |model_class|
      with_instance_of(model_class) do |record|
        old_friendly_id = record.friendly_id
        record.name = record.name + "b"
        record.slug = nil
        record.save!
        begin
          assert model_class.find(old_friendly_id)
          assert model_class.exists?(old_friendly_id), "should exist? by old id for #{model_class.name}"
        rescue ActiveRecord::RecordNotFound => e
          flunk "Could not find record by old id for #{model_class.name}"
        end
      end
    end
  end
end

class City < ActiveRecord::Base
  has_many :restaurants
end

class Restaurant < ActiveRecord::Base
  extend FriendlyId
  belongs_to :city
  friendly_id :name, :use => [:scoped, :history], :scope => :city
end

class ScopedHistoryTest < Minitest::Test
  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core

  def model_class
    Restaurant
  end

  test "should find old scoped slugs" do
    transaction do
      city = City.create!
      with_instance_of(Restaurant) do |record|
        record.city = city

        record.name = "x"
        record.slug = nil
        record.save!

        record.name = "y"
        record.slug = nil
        record.save!

        assert_equal city.restaurants.friendly.find("x"), city.restaurants.friendly.find("y")
      end
    end
  end

  test "should consider old scoped slugs when creating slugs" do
    transaction do
      city = City.create!
      with_instance_of(Restaurant) do |record|
        record.city = city

        record.name = "x"
        record.slug = nil
        record.save!

        record.name = "y"
        record.slug = nil
        record.save!

        second_record = model_class.create! :city => city, :name => 'x'
        assert_match(/x-.+/, second_record.friendly_id)

        third_record = model_class.create! :city => city, :name => 'y'
        assert_match(/y-.+/, third_record.friendly_id)
      end
    end
  end

  test "should allow equal slugs in different scopes" do
    transaction do
      city = City.create!
      second_city = City.create!
      record = model_class.create! :city => city, :name => 'x'
      second_record = model_class.create! :city => second_city, :name => 'x'

      assert_equal record.slug, second_record.slug
    end
  end
end