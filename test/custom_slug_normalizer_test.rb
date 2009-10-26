# encoding: utf-8

require File.dirname(__FILE__) + '/test_helper'

class CustomSlugNormalizerTest < Test::Unit::TestCase

  context "A slugged model using a custom slug generator" do

    setup do
      Thing.friendly_id_options = FriendlyId::DEFAULT_FRIENDLY_ID_OPTIONS.merge(:column => :name, :use_slug => true)
    end

    teardown do
      Thing.delete_all
      Slug.delete_all
    end

    should "invoke the block code" do
      @thing = Thing.create!(:name => "test")
      assert_equal "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", @thing.friendly_id
    end

    should "respect the max_length option" do
      Thing.friendly_id_options = Thing.friendly_id_options.merge(:max_length => 10)
      @thing = Thing.create!(:name => "test")
      assert_equal "a94a8fe5cc", @thing.friendly_id
    end

    should "respect the reserved option" do
      Thing.friendly_id_options = Thing.friendly_id_options.merge(:reserved => ["a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"])
      assert_raises FriendlyId::SlugGenerationError do
        Thing.create!(:name => "test")
      end
    end

  end

end
