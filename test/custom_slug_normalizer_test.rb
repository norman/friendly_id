require File.dirname(__FILE__) + '/test_helper'

class CustomSlugNormalizerTest < Test::Unit::TestCase

  context "A slugged model using a custom slug generator" do

    setup do
      Person.friendly_id_options = FriendlyId::DEFAULT_OPTIONS.merge(:method => :name, :use_slug => true)
    end

    teardown do
      Person.delete_all
      Slug.delete_all
    end

    should "invoke the block code" do
      @person = Person.create!(:name => "Joe Schmoe")
      assert_equal "JOE SCHMOE", @person.friendly_id
    end

    should "respect the max_length option" do
      Person.friendly_id_options = Person.friendly_id_options.merge(:max_length => 3)
      @person = Person.create!(:name => "Joe Schmoe")
      assert_equal "JOE", @person.friendly_id
    end

    should "respect the reserved option" do
      Person.friendly_id_options = Person.friendly_id_options.merge(:reserved => ["JOE"])
      assert_raises FriendlyId::SlugGenerationError do
        Person.create!(:name => "Joe")
      end
    end

  end

end
