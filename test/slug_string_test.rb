# encoding: utf-8
require File.dirname(__FILE__) + '/test_helper'

class SlugStringTest < Test::Unit::TestCase

  context "the SlugString class" do

    should "approximate ascii" do
      # create string with range of Unicode's western characters with
      # diacritics, excluding the division and multiplication signs which for
      # some reason or other are floating in the middle of all the letters.
      s = SlugString.new((0xC0..0x17E).to_a.reject {|c| [0xD7, 0xF7].include? c}.pack("U*"))
      output = s.approximate_ascii
      assert(output.length > s.length)
      assert_match output, /^[a-zA-Z']*$/
    end
    
    should "strip non-letters" do
      s = SlugString.new "¡feliz año!"
      assert_equal "feliz año", s.letters
    end

  end

  context "the Slug class's normalize method" do

      should "should lowercase  strings" do
        assert_equal "feliz año", SlugString.new("FELIZ AÑO").downcase
      end

      should "should uppercase  strings" do
        assert_equal "FELIZ AÑO", SlugString.new("feliz año").upcase
      end

      should "should replace whitespace with dashes" do
        assert_equal 'a-b', SlugString.new("a b").clean.with_dashes
      end
  
      should "should replace multiple spaces with 1 dash" do
        assert_equal 'a-b', SlugString.new("a    b").clean.with_dashes
      end
   
      should "should strip trailing space" do
        assert_equal 'ab', SlugString.new("ab ").clean
      end
  
      should "should strip leading space" do
        assert_equal 'ab', SlugString.new(" ab").clean
      end
  
      should "should strip trailing slashes" do
        assert_equal 'ab', SlugString.new("ab-").clean
      end
  
      should "should strip leading slashes" do
        assert_equal 'ab', SlugString.new("-ab").clean
      end
  
      should "should not modify valid name strings" do
        assert_equal 'a-b-c-d', SlugString.new("a-b-c-d").clean
      end
      
      should "do special approximations for German" do
        assert_equal "Juergen", SlugString.new("Jürgen").approximate_ascii(:german)
      end

      should "do special approximations for Spanish" do
        assert_equal "anno", SlugString.new("año").approximate_ascii(:spanish)
      end
  
      should "work with non roman chars" do
        assert_equal "検-索", SlugString.new("検 索").with_dashes
      end
  end
end
