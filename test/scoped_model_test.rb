require File.dirname(__FILE__) + '/test_helper'

class ScopedModelTest < Test::Unit::TestCase

  fixtures :people, :countries, :slugs
  
  def test_should_find_scoped_records_without_scope
    assert_equal 2, Person.find(:all, "john-smith").size
  end

  def test_should_find_scoped_records_with_scope
    assert_equal people(:john_smith), Person.find("john-smith", :scope => "argentina")
    assert_equal people(:john_smith2), Person.find("john-smith", :scope => "usa")
  end
  
  def test_should_create_scoped_records_with_scope
    person = Person.create!(:name => "Joe Schmoe", :country => countries(:usa))
    assert_equal "usa", person.slug.scope
  end

end