# encoding: utf-8

require File.dirname(__FILE__) + '/test_helper'

class CachedSlugModelTest < Test::Unit::TestCase

  context "A slugged model with a cached_slugs column" do

    setup do
      City.delete_all
      Slug.delete_all
      @paris = City.new(:name => "Paris")
      @paris.save!
    end

    should "have a slug" do
      assert_not_nil @paris.slug
    end

    should "have a cached slug" do
      assert_not_nil @paris.cached_slug
    end

    should "have a to_param method that returns the cached slug" do
      assert_equal "paris", @paris.to_param
    end

    context "found by its friendly id" do

      setup do
        @paris = City.find(@paris.friendly_id)
      end

      should "not indicate that it has a better id" do
        assert !@paris.has_better_id?
      end

    end


    context "found by its numeric id" do

      setup do
        @paris = City.find(@paris.id)
      end

      should "indicate that it has a better id" do
        assert @paris.has_better_id?
      end

    end


    context "with a new slug" do

      setup do
        @paris.name = "Paris, France"
        @paris.save
      end

      should "have its cached_slug updated" do
        assert_equal "paris-france", @paris.cached_slug
      end

      should "have its cached_slug synchronized with its friendly_id" do
        assert_equal @paris.cached_slug, @paris.friendly_id
      end

    end

  end

end

