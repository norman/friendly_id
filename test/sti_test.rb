require File.dirname(__FILE__) + '/test_helper'

class STIModelTest < Test::Unit::TestCase

  context "A slugged model using single table inheritance" do

    setup do
      Novel.friendly_id_options = FriendlyId::DEFAULT_OPTIONS.merge(:method => :name, :use_slug => true)
      @novel = Novel.new :name => "Test novel"
      @novel.save!
    end

    teardown do
      Novel.delete_all
      Slug.delete_all
    end

    should "have a slug" do
      assert_not_nil @novel.slug
    end

    context "found by its friendly id" do

      setup do
        @novel = Novel.find(@novel.friendly_id)
      end

      should "not indicate that it has a better id" do
        assert !@novel.has_better_id?
      end

    end


    context "found by its numeric id" do

      setup do
        @novel = Novel.find(@novel.id)
      end

      should "indicate that it has a better id" do
        assert @novel.has_better_id?
      end

    end

  end

end
