require(File.dirname(__FILE__) + '/test_helper')
require File.dirname(__FILE__) + '/../../lib/friendly_id/active_record2/tasks'

class TasksTest < Test::Unit::TestCase

  def teardown
    ENV["MODEL"] = nil
    [City, District, Post, Slug].map(&:delete_all)
  end

  test "should make slugs" do
    City.create! :name => "Nairobi"
    City.create! :name => "Buenos Aires"
    Slug.delete_all
    ENV["MODEL"] = "City"
    FriendlyId::TaskRunner.new.make_slugs
    assert_equal 2, Slug.count
  end

  test "should admit lower case, plural model names" do
    ENV["MODEL"] = "cities"
    assert_equal City, FriendlyId::TaskRunner.new.klass
  end

  test "make_slugs should raise error if no model given" do
    assert_raise(RuntimeError) { FriendlyId::TaskRunner.new.make_slugs }
  end

  test "make_slugs should raise error if class doesn't use FriendlyId" do
    ENV["MODEL"] = "String"
    assert_raise(RuntimeError) { FriendlyId::TaskRunner.new.make_slugs }
  end

  test"delete_slugs delete only slugs for the specified model" do
    Post.create! :name => "Slugs Considered Harmful"
    City.create! :name => "Buenos Aires"
    ENV["MODEL"] = "city"
    FriendlyId::TaskRunner.new.delete_slugs
    assert_equal 1, Slug.count
  end

  test "delete_slugs should set the cached_slug column to NULL" do
    ENV["MODEL"] = "district"
    District.create! :name => "Garment"
    FriendlyId::TaskRunner.new.delete_slugs
    assert_nil District.first.cached_slug
  end


  test "delete_old_slugs should delete slugs older than 45 days by default" do
    set_up_old_slugs
    FriendlyId::TaskRunner.new.delete_old_slugs
    assert_equal 2, Slug.count
  end

  test "delete_old_slugs should respect the days argument" do
    set_up_old_slugs
    ENV["DAYS"] = "100"
    FriendlyId::TaskRunner.new.delete_old_slugs
    assert_equal 3, Slug.count
  end

  test "delete_old_slugs should respect the class argument" do
    set_up_old_slugs
    ENV["MODEL"] = "post"
    FriendlyId::TaskRunner.new.delete_old_slugs
    assert_equal 3, Slug.count
  end

  private

  def set_up_old_slugs
    Post.create! :name => "Slugs Considered Harmful"
    city = City.create! :name => "Buenos Aires"
    City.connection.execute "UPDATE slugs SET created_at = '%s' WHERE id = %d" % [
      45.days.ago.strftime("%Y-%m-%d"), city.slug.id
    ]
    city.update_attributes :name => "Ciudad de Buenos Aires"
    assert_equal 3, Slug.count
  end

end
