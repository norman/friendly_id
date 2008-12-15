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

  # See FriendlyId::StringHelper for more specific normalize tests.
  def test_normalize_should_invoke_strings_to_friendly_id_method
    string = "any string"
    string.expects(:to_friendly_id)
    Slug::normalize(string)
  end

end