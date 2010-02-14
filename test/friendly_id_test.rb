require(File.dirname(__FILE__) + "/test_helper")

module FriendlyId

  module Test

    class FriendlyIdTest < ::Test::Unit::TestCase

      test "should parse a friendly_id name and sequence" do
        assert_equal ["test", "2"], "test--2".parse_friendly_id
      end

      test "should parse with a default sequence of 1" do
        assert_equal ["test", "1"], "test".parse_friendly_id
      end

      test "should be parseable with a custom separator" do
        assert_equal ["test", "2"], "test:2".parse_friendly_id(":")
      end

      test "should parse when default sequence seperator also occurs in friendly_id name" do
        assert_equal ["test--test", "2"], "test--test--2".parse_friendly_id
      end

      test "should parse when custom sequence seperator also occurs in friendly_id name" do
        assert_equal ["test:test", "2"], "test:test:2".parse_friendly_id(":")
      end

    end
  end
end