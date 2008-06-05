require File.dirname(__FILE__) + '/test_helper'

class UniqueColumnTest < Test::Unit::TestCase
  
  fixtures :users
  
  def setup
  end
  
  def test_should_find_user_using_friendly_id
    assert User.find(users(:joe).friendly_id)
  end
  
  def test_should_find_users_using_friendly_ids
    assert_equal 2, User.find([users(:joe).friendly_id, users(:jane).friendly_id]).length
  end
  
  def test_should_not_find_users_using_non_existent_friendly_ids
    assert_equal [], User.find(['non-existen-slug', 'yet-another-non-existent-slug'])
  end
  
  def test_finder_options_are_not_ignored
    assert_raises ActiveRecord::RecordNotFound do
       User.find(users(:joe).friendly_id, :conditions => "1 = 2")
    end
  end

  def test_user_should_have_friendly_id_options
    assert_not_nil User.friendly_id_options
  end

  def test_user_should_not_be_found_using_friendly_id_unless_it_really_was
    @user = User.new
    assert !@user.found_using_friendly_id?
  end
  
  def test_user_should_be_considered_found_by_numeric_id_as_default
    @user = User.new
    assert @user.found_using_numeric_id?  
  end

  def test_user_should_indicate_if_it_was_found_using_numeric_id
    @user = User.find(users(:joe).id)
    assert @user.found_using_numeric_id?
  end

  def test_user_should_indicate_if_it_was_found_using_friendly_id
    @user = User.find(users(:joe).friendly_id)
    assert @user.found_using_friendly_id?
  end

  def test_should_indicate_there_is_a_better_id_if_found_by_numeric_id
    @user = User.find(users(:joe).id)
    assert @user.has_better_id?
  end
  
end