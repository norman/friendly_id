require File.dirname(__FILE__) + '/test_helper'

class CustomSlugNormalizerTest < Test::Unit::TestCase

  context "A slugged model using a custom slug generator" do

    teardown do
      Person.delete_all
      $slug_class.delete_all
    end

    should "invoke the block code" do
      @person = Person.create!(:name => "Joe Schmoe")
      assert_equal "JOE SCHMOE", @person.friendly_id
    end

    should "respect the max_length option" do
      Person.friendly_id_config.stubs(:max_length).returns(3)
      @person = Person.create!(:name => "Joe Schmoe")
      assert_equal "JOE", @person.friendly_id
    end

    should "respect the reserved option" do
      Person.friendly_id_config.stubs(:reserved_words).returns(["JOE"])
      assert_raises FriendlyId::SlugTextReservedError do
        Person.create!(:name => "Joe")
      end
    end

  end

end
