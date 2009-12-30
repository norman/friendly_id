require File.dirname(__FILE__) + '/test_helper'

class FriendlyIdTest < Test::Unit::TestCase

  context "the FriendlyId module" do

    should "parse a friendly_id name and sequence" do
      assert_equal ["test", "2"], FriendlyId.parse("test--2")
    end

    should "parse with a default sequence of 1" do
      assert_equal ["test", "1"], FriendlyId.parse("test")
    end

  end

end
