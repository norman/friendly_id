require File.dirname(__FILE__) + '/test_helper'


class ScopedModelTest < Test::Unit::TestCase

  setup do
    @user = User.create!(:name => "john")
    @house = House.create!(:name => "123 Main", :user => @user)
    @usa = Country.create!(:name => "USA")
    @canada = Country.create!(:name => "Canada")
    @resident = Resident.create!(:name => "John Smith", :country => @usa)
    @resident2 = Resident.create!(:name => "John Smith", :country => @canada)
  end

  teardown do
    Resident.delete_all
    Country.delete_all
    User.delete_all
    House.delete_all
    FriendlyId::Adapters::ActiveRecord::Slug.delete_all
  end

  context "A slugged model used as a scope for another model" do

    should "auto-detect that it is being used as a parent scope" do
      assert_equal [Resident], Country.friendly_id_config.child_scopes
    end

    should "update its child model's scopes when its friendly_id changes" do
      @usa.update_attributes(:name => "United States")
      assert_equal "united-states", @usa.to_param
      assert_equal "united-states", @resident.slugs(true).first.scope
    end

  end

  context "A non-slugged model used as a scope for another model" do

    should "auto-detect that it is being used as a parent scope" do
      assert_equal [House], User.friendly_id_config.child_scopes
    end

    should "update its child model's scopes when its friendly_id changes" do
      @user.update_attributes(:name => "jack")
      assert_equal "jack", @user.to_param
      assert_equal "jack", @house.slugs(true).first.scope
    end

  end


  context "A slugged model that uses a slugged model as a scope" do

    should "should not show the scope in the friendly_id" do
      assert_equal "john-smith", @resident.friendly_id
      assert_equal "john-smith", @resident2.friendly_id
    end

    should "find all scoped records without scope" do
      assert_equal 2, Resident.find(:all, @resident.friendly_id).size
    end

    should "find a single scoped record with a scope as a string" do
      assert Resident.find(@resident.friendly_id, :scope => @resident.country)
    end

    should "find a single scoped record with a scope" do
      assert Resident.find(@resident.friendly_id, :scope => @resident.country)
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
        assert_match(/scope: expected/, e.message)
      end
    end

    should "append scope error info when the scope value causes a find to fail" do
      begin
        Resident.find(@resident.friendly_id, :scope => "badscope")
        fail "The find should not have succeeded"
      rescue ActiveRecord::RecordNotFound => e
        assert_match(/scope: badscope/, e.message)
      end
    end

  end

end