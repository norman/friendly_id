require File.dirname(__FILE__) + '/test_helper'

class NonSluggedTest < Test::Unit::TestCase

  fixtures :users

  def setup
  end

  def test_should_find_user_using_friendly_id
    assert User.find(users(:joe).friendly_id)
  end

  def test_should_find_users_using_friendly_id
    assert User.find([users(:joe).friendly_id])
  end

  def test_to_param_should_return_a_string
    assert_equal String, users(:joe).to_param.class
  end

  def test_should_not_find_users_using_non_existent_friendly_ids
    assert_raises ActiveRecord::RecordNotFound do
      User.find(['bad', 'bad2'])
    end
  end
  
  def test_finding_by_array_with_friendly_and_non_friendly_id_for_same_record_raises_error
    assert_raises ActiveRecord::RecordNotFound do
      User.find([users(:joe).id, "joe"]).size
    end
  end

  def test_finding_with_mixed_array_should_indicate_whether_found_by_numeric_or_friendly
    @users = User.find([users(:jane).id, "joe"], :order => "login ASC")
    assert @users[0].found_using_numeric_id?
    assert @users[1].found_using_friendly_id?
  end

  def test_finder_options_are_not_ignored
    assert_raises ActiveRecord::RecordNotFound do
       User.find(users(:joe).friendly_id, :conditions => "1 = 2")
    end
    assert_raises ActiveRecord::RecordNotFound do
       User.find([users(:joe).friendly_id], :conditions => "1 = 2")
    end
  end

  def test_user_should_have_friendly_id_options
    assert_not_nil User.friendly_id_options
  end

  def test_user_should_not_be_found_using_friendly_id_unless_it_really_was
    assert !User.find(users(:joe).id).found_using_friendly_id?
  end

  def test_users_should_not_be_found_using_friendly_id_unless_they_really_were
    @users = User.find([users(:jane).id])
    assert @users[0].found_using_numeric_id?
  end

  def test_user_should_be_considered_found_by_numeric_id_as_default
    @user = User.new
    assert @user.found_using_numeric_id?
  end

  def test_user_should_indicate_if_it_was_found_using_numeric_id
    @user = User.find(users(:joe).id)
    assert @user.found_using_numeric_id?
    assert !@user.found_using_friendly_id?
  end

  def test_user_should_indicate_if_it_was_found_using_friendly_id
    @user = User.find(users(:joe).friendly_id)
    assert !@user.found_using_numeric_id?
    assert @user.found_using_friendly_id?
  end

  def test_should_indicate_there_is_a_better_id_if_found_by_numeric_id
    @user = User.find(users(:joe).id)
    assert @user.found_using_numeric_id?
    assert @user.has_better_id?
  end

end