require "helper"

using FriendlyId::ObjectUtils

class ObjectUtilsTest < TestCaseClass

  include FriendlyId::Test

  test "strings with letters are friendly_ids" do
    assert "a".friendly_id?
    assert "a".possibly_friendly_id?
    refute "a".unfriendly_id?
  end

  test "integers should be unfriendly ids" do
    refute 1.friendly_id?
    refute 1.possibly_friendly_id?
    assert 1.unfriendly_id?
  end

  test "numeric strings are neither friendly nor unfriendly but are possibly friendly" do
    assert_nil "1".friendly_id?
    assert "1".possibly_friendly_id?
    assert_nil "1".unfriendly_id?
  end

  test "ActiveRecord::Base instances should be unfriendly_ids" do
    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "authors"
    end
    refute model_class.new.friendly_id?
    refute model_class.new.possibly_friendly_id?
    assert model_class.new.unfriendly_id?
  end

  test "any object that responds to to_i and to_s" do
    TestClass=Struct.new(:to_i,:to_s)
    numericish_string_object = TestClass.new(123, "123abc")

    assert numericish_string_object.friendly_id?
    assert numericish_string_object.possibly_friendly_id?
    refute numericish_string_object.unfriendly_id?
  end

end