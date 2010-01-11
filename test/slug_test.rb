# encoding: utf-8
require File.dirname(__FILE__) + '/test_helper'

class SlugTest < Test::Unit::TestCase

  context "a slug" do

    teardown do
      FriendlyId::Adapters::ActiveRecord::Slug.delete_all
      Post.delete_all
    end

    should "indicate if it is the most recent slug" do
      post = Post.create!(:name => "test title")
      post.name = "a new title"
      post.save!
      assert post.slugs.last.is_most_recent?
      assert !post.slugs.first.is_most_recent?
    end

  end

  context "the Slug class's to_friendly_id method" do

    should "include the sequence if the sequence is greater than 1" do
      slug = FriendlyId::Adapters::ActiveRecord::Slug.new(:name => "test", :sequence => 2)
      slug.stubs(:sluggable).returns Post.new
      assert_equal "test--2", slug.to_friendly_id
    end

    should "not include the sequence if the sequence is 1" do
      slug = FriendlyId::Adapters::ActiveRecord::Slug.new(:name => "test", :sequence => 1)
      slug.stubs(:sluggable).returns Post.new
      assert_equal "test", slug.to_friendly_id
    end

  end

end
