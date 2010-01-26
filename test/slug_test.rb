# encoding: utf-8
require(File.dirname(__FILE__) + '/test_helper') unless defined? FriendlyId

module FriendlyId
  module Test

    class SlugTest < ::Test::Unit::TestCase

      extend Declarative

      def teardown
        $slug_class.delete_all
        Post.delete_all
      end

      test "should indicate if it is the most recent slug" do
        post = Post.create!(:name => "test title")
        post.name = "a new title"
        post.save!
        assert post.slugs.first.current?
        assert !post.slugs.last.current?
      end

      test "should include the sequence if the sequence is greater than 1" do
        slug = $slug_class.new(:name => "test", :sequence => 2)
        slug.stubs(:sluggable).returns Post.new
        assert_equal "test--2", slug.to_friendly_id
      end

      test "should not include the sequence if the sequence is 1" do
        slug = $slug_class.new(:name => "test", :sequence => 1)
        slug.stubs(:sluggable).returns Post.new
        assert_equal "test", slug.to_friendly_id
      end

    end
  end
end