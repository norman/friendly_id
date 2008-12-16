require File.dirname(__FILE__) + '/test_helper'

class SlugTest < Test::Unit::TestCase

  fixtures :posts, :slugs

  def test_should_indicate_if_it_is_the_most_recent
    assert slugs(:two_new).is_most_recent?
    assert !slugs(:two_old).is_most_recent?
  end

  def test_parse_should_return_slug_name_and_sequence
    assert_equal ["test", "2"], Slug::parse("test--2")
  end

  def test_parse_should_return_a_default_sequnce_of_1
    assert_equal ["test", "1"], Slug::parse("test")
  end

  def test_strip_diacritics_should_strip_diacritics
    assert_equal "acai", Slug::strip_diacritics("açaí")
  end

  def test_to_friendly_id_should_include_sequence_if_its_greater_than_1
    slug = Slug.new(:name => "test", :sequence => 2)
    assert_equal "test--2", slug.to_friendly_id
  end

  def test_to_friendly_id_should_include_sequence_if_its_than_1
    slug = Slug.new(:name => "test", :sequence => 1)
    assert_equal "test", slug.to_friendly_id
  end

  def test_normalize_should_lowercase_strings
    assert_match /abc/, Slug::normalize("ABC")
  end

  def test_normalize_should_replace_whitespace_with_dashes
    assert_match /a-b/, Slug::normalize("a b")
  end

  def test_normalize_should_replace_2spaces_with_1dash
    assert_match /a-b/, Slug::normalize("a  b")
  end

  def test_normalize_should_remove_punctuation
    assert_match /abc/, Slug::normalize('abc!@#$%^&*•¶§∞¢££¡¿()><?"":;][]\.,/')
  end

  def test_normalize_should_strip_trailing_space
    assert_match /ab/, Slug::normalize("ab ")
  end

  def test_normalize_should_strip_leading_space
    assert_match /ab/, Slug::normalize(" ab")
  end

  def test_normalize_should_strip_trailing_slashes
    assert_match /ab/, Slug::normalize("ab-")
  end

  def test_normalize_should_strip_leading_slashes
    assert_match /ab/, Slug::normalize("-ab")
  end

  def test_normalize_should_not_modify_valid_name_strings
    assert_match /a-b-c-d/, Slug::normalize("a-b-c-d")
  end

  # These strings are taken from various international Google homepages. I
  # would be most grateful if a fluent speaker of any language that uses a
  # writing system other than the Roman alphabet could help me make some
  # better tests to ensure this is working correctly.
  def test_normalize_works_with_non_roman_chars
    assert_equal "検-索", Slug::normalize("検 索")
  end

  def test_strip_diactics_correctly_strips_diacritics
    input  = "ÀÁÂÃÄÅÆÇÈÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ"
    output = Slug::strip_diacritics(input).split(//)
    expected = "AAAAAAAECEEEIIIIDNOOOOOOUUUUYThssaaaaaaaeceeeeiiiidnoooooouuuuythy".split(//)
    output.split.each_index do |i|
      assert_equal output[i], expected[i]
    end
  end
  
end