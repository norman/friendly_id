require File.dirname(__FILE__) + '/test_helper'

class ScopedModelTest < Test::Unit::TestCase

  context "A slugged model that uses a scope" do

    setup do
      Person.delete_all
      Country.delete_all
      Slug.delete_all
      @usa = Country.create!(:name => "USA")
      @canada = Country.create!(:name => "Canada")
      @person = Person.create!(:name => "John Smith", :country => @usa)
      @person2 = Person.create!(:name => "John Smith", :country => @canada)
    end

    should "find all scoped records without scope" do
      assert_equal 2, Person.find(:all, @person.friendly_id).size
    end

    should "find a single scoped records with a scope" do
      assert Person.find(@person.friendly_id, :scope => @person.country.to_param)
    end

    should "raise an error when finding a single scoped record with no scope" do
      assert_raises ActiveRecord::RecordNotFound do
        Person.find(@person.friendly_id)
      end
    end

    should "append scope error info when missing scope causes a find to fail" do
      begin
        Person.find(@person.friendly_id)
        fail "The find should not have succeeded"
      rescue ActiveRecord::RecordNotFound => e
        assert_match /expected scope/, e.message
      end
    end

    should "append scope error info when the scope value causes a find to fail" do
      begin
        Person.find(@person.friendly_id, :scope => "badscope")
        fail "The find should not have succeeded"
      rescue ActiveRecord::RecordNotFound => e
        assert_match /scope=badscope/, e.message
      end
    end

  end

end