# encoding: utf-8

require File.dirname(__FILE__) + '/test_helper'

class SlugTest < Test::Unit::TestCase

  context "a slug" do
    
    setup do
      Slug.delete_all
      Post.delete_all
    end

    should "indicate if it is the most recent slug" do
      @post = Post.create!(:title => "test title", :content => "test content")
      @post.title = "a new title"
      @post.save!
      assert @post.slugs.last.is_most_recent?
      assert !@post.slugs.first.is_most_recent?
    end

  end
  
  context "the Slug class" do
    
    should "parse the slug name and sequence" do
      assert_equal ["test", "2"], Slug::parse("test--2")
    end
    
    should "parse with a default sequence of 1" do
      assert_equal ["test", "1"], Slug::parse("test")
    end

    should "should strip diacritics" do
      assert_equal "acai", Slug::strip_diacritics("açaí")
    end
  
    should "strip diacritics correctly " do
      input  = "ÀÁÂÃÄÅÆÇÈÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ"
      output = Slug::strip_diacritics(input).split(//)
      expected = "AAAAAAAECEEEIIIIDNOOOOOOUUUUYThssaaaaaaaeceeeeiiiidnoooooouuuuythy".split(//)
      output.split.each_index do |i|
        assert_equal output[i], expected[i]
      end
    end
  
  end
  
  context "the Slug class's to_friendly_id method" do
    
    should "include the sequence if the sequence is greater than 1" do
      slug = Slug.new(:name => "test", :sequence => 2)
      assert_equal "test--2", slug.to_friendly_id
    end
  
    should "not include the sequence if the sequence is 1" do
      slug = Slug.new(:name => "test", :sequence => 1)
      assert_equal "test", slug.to_friendly_id
    end
    
  end
  
  context "the Slug class's normalize method" do  
    
    should "should lowercase  strings" do
      assert_match /abc/, Slug::normalize("ABC")
    end
  
    should "should replace whitespace with dashes" do
      assert_match /a-b/, Slug::normalize("a b")
    end
  
    should "should replace 2spaces with 1dash" do
      assert_match /a-b/, Slug::normalize("a  b")
    end
  
    should "should remove punctuation" do
      assert_match /abc/, Slug::normalize('abc!@#$%^&*•¶§∞¢££¡¿()><?"":;][]\.,/')
    end
  
    should "should strip trailing space" do
      assert_match /ab/, Slug::normalize("ab ")
    end
  
    should "should strip leading space" do
      assert_match /ab/, Slug::normalize(" ab")
    end
  
    should "should strip trailing slashes" do
      assert_match /ab/, Slug::normalize("ab-")
    end
  
    should "should strip leading slashes" do
      assert_match /ab/, Slug::normalize("-ab")
    end
  
    should "should not modify valid name strings" do
      assert_match /a-b-c-d/, Slug::normalize("a-b-c-d")
    end
  
    should "work with non roman chars" do
      assert_equal "検-索", Slug::normalize("検 索")
    end
  
  end
end