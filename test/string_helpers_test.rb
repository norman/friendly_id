require File.dirname(__FILE__) + '/test_helper'

class StringHelpersTest < Test::Unit::TestCase

  def test_normalize_should_lowercase_strings
    assert_match /abc/, "ABC".to_friendly_id
  end

  def test_normalize_should_replace_whitespace_with_dashes
    assert_match /a-b/, "a b".to_friendly_id
  end

  def test_normalize_should_replace_2spaces_with_1dash
    assert_match /a-b/, "a  b".to_friendly_id
  end

  def test_normalize_should_delete_punctuation
    assert_match /abc/, 'abc!@#$%^&*()><?"":;][]\.,/'.to_friendly_id
  end

  def test_normalize_should_strip_trailing_space
    assert_match /ab/, "ab ".to_friendly_id
  end

  def test_normalize_should_strip_leading_space
    assert_match /ab/, " ab".to_friendly_id
  end

  def test_normalize_should_strip_trailing_slashes
    assert_match /ab/, "ab-".to_friendly_id
  end

  def test_normalize_should_strip_leading_slashes
    assert_match /ab/, "-ab".to_friendly_id
  end

  def test_normalize_should_not_modify_valid_name_strings
    assert_match /a-b-c-d/, "a-b-c-d".to_friendly_id
  end
  
  def test_normalize_works_with_non_western_chars
    assert_equal "検-索", "検 索".to_friendly_id
    assert_equal "דפים-מישראל", "דפים מישראל".to_friendly_id
    assert_equal "لبحث-في-ويب", "لبحث في ويب".to_friendly_id
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