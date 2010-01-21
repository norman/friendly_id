require File.dirname(__FILE__) + '/test_helper'

class NonSluggedTest < Test::Unit::TestCase

  context "A non-slugged model with default FriendlyId options" do

    setup do
      @user = User.create!(:name => "joe")
    end

    teardown do
      User.delete_all
    end
    
    should "have a friendly_id config" do
      assert_not_nil User.friendly_id_config
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
      user = User.find(@user.friendly_id)
      assert user.friendly_id_status.friendly?
    end

    should "indicate if it was found by its numeric id" do
      user = User.find(@user.id)
      assert user.friendly_id_status.numeric?
    end

    should "indicate if it has a better id" do
      user = User.find(@user.id)
      assert !user.friendly_id_status.best?
    end

    should "not validate if the friendly_id text is reserved" do
      user = User.new(:name => "new")
      assert !user.valid?
    end

    should "have always string for a friendly_id" do
      assert_equal String, @user.to_param.class
    end

    should "return its id if the friendly_id is null" do
      @user.name = nil
      assert_equal @user.id.to_s, @user.to_param
    end


    context "when using an array as the find argument" do

      setup do
        @user2 = User.create(:name => "jane")
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
        users = User.find([@user.id, @user2.friendly_id], :order => "name ASC")
        assert users[0].friendly_id_status.friendly?
        assert users[1].friendly_id_status.numeric?
      end

    end

  end

end
