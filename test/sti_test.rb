# encoding: utf-8

require File.dirname(__FILE__) + '/test_helper'

class SluggedModelTest < Test::Unit::TestCase

  context "A slugged model using single table inheritance" do

    setup do
      Novel.friendly_id_options = FriendlyId::DEFAULT_FRIENDLY_ID_OPTIONS.merge(:column => :title, :use_slug => true)
      Novel.delete_all
      Slug.delete_all
      @novel = Novel.new :title => "Test novel"
      @novel.save!
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