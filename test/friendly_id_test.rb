# require File.dirname(__FILE__) + '/test_helper'

class FriendlyIdTest < Test::Unit::TestCase

  test "should parse a friendly_id name and sequence" do
    assert_equal ["test", "2"], "test--2".parse_friendly_id
  end

  test "should parse with a default sequence of 1" do
    assert_equal ["test", "1"], "test".parse_friendly_id
  end

  test "should be parseable with a custom separator" do
    assert_equal ["test", "2"], "test:2".parse_friendly_id(":")
  end

end
