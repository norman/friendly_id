require File.dirname(__FILE__) + '/test_helper'

class CachedSlugModelTest < Test::Unit::TestCase

  context "A slugged model with a cached_slugs column" do

    setup do
      @paris = City.new(:name => "Paris")
      @paris.save!
    end

    teardown do
      City.delete_all
      Slug.delete_all
    end

    should "have a slug" do
      assert_not_nil @paris.slug
    end

    should "have a cached slug" do
      assert_not_nil @paris.my_slug
    end

    should "have a to_param method that returns the cached slug" do
      assert_equal "paris", @paris.to_param
    end

    should "protect the cached slug value" do
      @paris.update_attributes(:my_slug => "Madrid")
      @paris.reload
      assert_equal "paris", @paris.my_slug
    end

    should "cache the incremented sequence for duplicate slug names" do
      paris2 = City.create!(:name => "Paris")
      assert_equal 2, paris2.slug.sequence
      assert_equal "paris--2", paris2.my_slug
    end

    should "not update the cached slug column if it has not changed" do
      @paris.population = 10_000_000
      @paris.expects(:my_slug=).never
      @paris.save
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
        @paris.save!
        @paris.reload
      end

      should "have its cached slug updated" do
        assert_equal "paris-france", @paris.my_slug
      end

      should "have its cached slug synchronized with its friendly_id" do
        assert_equal @paris.my_slug, @paris.friendly_id
      end

    end


    context "with a cached_slug column" do

      setup do
        District.delete_all
        @district = District.new(:name => "Latin Quarter")
        @district.save!
      end

      should "have its cached_slug filled automatically" do
        assert_equal @district.cached_slug, "latin-quarter"
      end

    end

  end

end

