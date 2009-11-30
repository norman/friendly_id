require File.dirname(__FILE__) + '/test_helper'


class ScopedModelTest < Test::Unit::TestCase

  context "A slugged model that uses a scope" do

    setup do
      @usa = Country.create!(:name => "USA")
      @canada = Country.create!(:name => "Canada")
      @resident = Resident.create!(:name => "John Smith", :country => @usa)
      @resident2 = Resident.create!(:name => "John Smith", :country => @canada)
    end

    teardown do
      Resident.delete_all
      Country.delete_all
      Slug.delete_all
    end

    should "should not show the scope in the friendly_id" do
      assert_equal "john-smith", @resident.friendly_id
      assert_equal "john-smith", @resident2.friendly_id
    end

    should "find all scoped records without scope" do
      assert_equal 2, Resident.find(:all, @resident.friendly_id).size
    end

    should "find a single scoped records with a scope" do
      assert Resident.find(@resident.friendly_id, :scope => @resident.country.to_param)
    end

    should "raise an error when finding a single scoped record with no scope" do
      assert_raises ActiveRecord::RecordNotFound do
        Resident.find(@resident.friendly_id)
      end
    end

    should "append scope error info when missing scope causes a find to fail" do
      begin
        Resident.find(@resident.friendly_id)
        fail "The find should not have succeeded"
      rescue ActiveRecord::RecordNotFound => e
        assert_match /expected scope/, e.message
      end
    end

    should "append scope error info when the scope value causes a find to fail" do
      begin
        Resident.find(@resident.friendly_id, :scope => "badscope")
        fail "The find should not have succeeded"
      rescue ActiveRecord::RecordNotFound => e
        assert_match /scope=badscope/, e.message
      end
    end

  end

end
