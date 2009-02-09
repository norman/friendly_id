require File.dirname(__FILE__) + '/test_helper'

class NonSluggedTest < Test::Unit::TestCase

  context "A non-slugged model with default FriendlyId options" do

    setup do
      User.delete_all
      @user = User.create!(:login => "joe", :email => "joe@example.org")
    end

    should "have friendly_id options" do
      assert_not_nil User.friendly_id_options
    end

    should "not have a slug" do
      assert !@user.respond_to?(:slug)
    end

    should "be findable by its friendly_id" do
      assert User.find(@user.friendly_id)
    end

    should "be findable by its regular id" do
      assert User.find(@user.id)
    end

    should "respect finder conditions" do
      assert_raises ActiveRecord::RecordNotFound do
        User.find(@user.friendly_id, :conditions => "1 = 2")
      end
    end

    should "indicate if it was found by its friendly id" do
      @user = User.find(@user.friendly_id)
      assert @user.found_using_friendly_id?
    end

    should "indicate if it was found by its numeric id" do
      @user = User.find(@user.id)
      assert @user.found_using_numeric_id?
    end

    should "indicate if it has a better id" do
      @user = User.find(@user.id)
      assert @user.has_better_id?
    end

    should "not validate if the friendly_id text is reserved" do
      @user = User.new(:login => "new", :email => "test@example.org")
      assert !@user.valid?
    end

    should "have always string for a friendly_id" do
      assert_equal String, @user.to_param.class
    end

    context "when using an array as the find argument" do

      setup do
        @user2 = User.create(:login => "jane", :email => "jane@example.org")
      end

      should "return results" do
        assert_equal 2, User.find([@user.friendly_id, @user2.friendly_id]).size
      end

      should "not allow mixed friendly and non-friendly ids for the same record" do
        assert_raises ActiveRecord::RecordNotFound do
          User.find([@user.id, @user.friendly_id]).size
        end
      end

      should "raise an error when all records are not found" do
        assert_raises ActiveRecord::RecordNotFound do
          User.find(['bad', 'bad2'])
        end
      end

      should "indicate if the results were found using a friendly_id" do
        @users = User.find([@user.id, @user2.friendly_id], :order => "login ASC")
        assert @users[0].found_using_friendly_id?
        assert @users[1].found_using_numeric_id?
      end

    end

  end

end