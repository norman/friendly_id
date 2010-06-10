# encoding: utf-8
require(File.expand_path("../test_helper", __FILE__))

module FriendlyId
  module Test

    class SlugStringTest < ::Test::Unit::TestCase

        test "should approximate ascii" do
          # create string with range of Unicode"s western characters with
          # diacritics, excluding the division and multiplication signs which for
          # some reason or other are floating in the middle of all the letters.
          s = SlugString.new((0xC0..0x17E).to_a.reject {|c| [0xD7, 0xF7].include? c}.pack("U*"))
          output = s.approximate_ascii
          assert(output.length > s.length)
          assert_match output, /^[a-zA-Z']*$/
        end

        test "should strip non-word chars" do
          s = SlugString.new "¡feliz año!"
          assert_equal "feliz año", s.word_chars
        end

        test "should lowercase  strings" do
          assert_equal "feliz año", SlugString.new("FELIZ AÑO").downcase
        end

        test "should uppercase  strings" do
          assert_equal "FELIZ AÑO", SlugString.new("feliz año").upcase
        end

        test "should replace whitespace with dashes" do
          assert_equal "a-b", SlugString.new("a b").clean.with_dashes
        end

        test "should replace multiple spaces with 1 dash" do
          assert_equal "a-b", SlugString.new("a    b").clean.with_dashes
        end

        test "should replace multiple dashes with 1 dash" do
          assert_equal "male-female", SlugString.new("male - female").with_dashes
        end

        test "should strip trailing space" do
          assert_equal "ab", SlugString.new("ab ").clean
        end

        test "should strip leading space" do
          assert_equal "ab", SlugString.new(" ab").clean
        end

        test "should strip trailing slashes" do
          assert_equal "ab", SlugString.new("ab-").clean
        end

        test "should strip leading slashes" do
          assert_equal "ab", SlugString.new("-ab").clean
        end

        test "should not modify valid name strings" do
          assert_equal "a-b-c-d", SlugString.new("a-b-c-d").clean
        end

        test "should do special approximations for German" do
          assert_equal "Juergen", SlugString.new("Jürgen").approximate_ascii(:german)
        end

        test "should do special approximations for Spanish" do
          assert_equal "anno", SlugString.new("año").approximate_ascii(:spanish)
        end

        test "should work with non roman chars" do
          assert_equal "検-索", SlugString.new("検 索").with_dashes
        end

        test "should work with invalid UTF-8 strings" do
          %w[approximate_ascii clean downcase word_chars normalize to_ascii upcase with_dashes].each do |method|
            string = SlugString.new("\x93abc")
            assert_nothing_raised do
              method == "truncate" ? string.send(method, 32) : string.send(method)
            end
          end

        end

    end
  end
end
