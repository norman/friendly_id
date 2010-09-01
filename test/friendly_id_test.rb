# encoding: utf-8
require File.expand_path('../test_helper', __FILE__)

module FriendlyId
  module Test

    class ConfigurationTest < ::Test::Unit::TestCase
      test "should validate sequence separator name" do
        ["-", " ", "\n", "\t"].each do |string|
          assert_raise ArgumentError do
            Configuration.new(NilClass, :hello, :sequence_separator => string)
          end
        end
      end

      test "should validate cached slug name" do
        ["slug", "slugs", " "].each do |string|
          assert_raise ArgumentError do
            Configuration.new(NilClass, :hello, :cache_column => string)
          end
        end
      end
    end

    class SlugStringTest < ::Test::Unit::TestCase
      test "should not transliterate by default" do
        s = SlugString.new("über")
        assert_equal "über", s.normalize_for!(Configuration.new(nil, :name))
      end

      test "should transliterate if specified" do
        s = SlugString.new("über")
        options = {:approximate_ascii => true}
        assert_equal "uber", s.normalize_for!(Configuration.new(nil, :name, options))
      end

      test "should strip non-ascii if specified" do
        s = SlugString.new("über")
        options = {:strip_non_ascii => true}
        assert_equal "ber", s.normalize_for!(Configuration.new(nil, :name, options))
      end

      test "should use transliterations if given" do
        s = SlugString.new("über")
        options = {:approximate_ascii => true, :ascii_approximation_options => :german}
        assert_equal "ueber", s.normalize_for!(Configuration.new(nil, :name, options))
      end
    end

    class FriendlyIdTest < ::Test::Unit::TestCase
      test "should parse a friendly_id name and sequence" do
        assert_equal ["test", 2], "test--2".parse_friendly_id
      end

      test "should parse a friendly_id name and a double digit sequence" do
        assert_equal ["test", 12], "test--12".parse_friendly_id
      end

      test "should parse with a default sequence of 1" do
        assert_equal ["test", 1], "test".parse_friendly_id
      end

      test "should be parseable with a custom separator" do
        assert_equal ["test", 2], "test:2".parse_friendly_id(":")
      end

      test "should be parseable with a custom separator and a double digit sequence" do
        assert_equal ["test", 12], "test:12".parse_friendly_id(":")
      end

      test "should parse when default sequence separator occurs in friendly_id name" do
        assert_equal ["test--test", 2], "test--test--2".parse_friendly_id
      end

      test "should parse when custom sequence separator occurs in friendly_id name" do
        assert_equal ["test:test", 2], "test:test:2".parse_friendly_id(":")
      end

      test "should parse when sequence separator and number occur in friendly_id name" do
        assert_equal ["test--2--test", 1], "test--2--test".parse_friendly_id
      end

      test "should parse when sequence separator, number and sequence occur in friendly_id name" do
        assert_equal ["test--2--test", 2], "test--2--test--2".parse_friendly_id
      end

      test "should parse when double digit sequence separator, number and sequence occur in friendly_id name" do
        assert_equal ["test--2--test", 12], "test--2--test--12".parse_friendly_id
      end

      test "should parse with a separator and no sequence" do
        assert_equal ["test", 1], "test--".parse_friendly_id
      end
    end
  end
end
