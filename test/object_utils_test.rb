require "helper"

using FriendlyId::ObjectUtils

class ObjectUtilsTest < TestCaseClass

  include FriendlyId::Test

  test "strings with letters are friendly_ids" do
    assert "a".friendly_id?
  end

  test "integers should be unfriendly ids" do
    assert 1.unfriendly_id?
  end

  test "numeric strings are neither friendly nor unfriendly" do
    assert_equal nil, "1".friendly_id?
    assert_equal nil, "1".unfriendly_id?
  end

  test "ActiveRecord::Base instances should be unfriendly_ids" do
    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "authors"
    end
    assert model_class.new.unfriendly_id?
  end
end