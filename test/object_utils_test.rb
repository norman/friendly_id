require "helper"

class ObjectUtilsTest < TestCaseClass
  include FriendlyId::Test

  test "strings with letters are friendly_ids" do
    assert "a".friendly_id?
  end

  test "integers should be unfriendly ids" do
    assert 1.unfriendly_id?
  end

  test "numeric strings are neither friendly nor unfriendly" do
    assert_nil "1".friendly_id?
    assert_nil "1".unfriendly_id?
  end

  test "ActiveRecord::Base instances should be unfriendly_ids" do
    FriendlyId.mark_as_unfriendly(ActiveRecord::Base)

    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "authors"
    end
    assert model_class.new.unfriendly_id?
  end

  # The kinds of argument that reach a finder.
  def sample_values
    FriendlyId.mark_as_unfriendly(ActiveRecord::Base)

    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "authors"
    end

    ["a", "abc123", "1", "", 1, 0, :id, nil, true, false, 1.5,
      ["name = ?", "joe"], {name: "joe"}, model_class.new]
  end

  test "the module functions return true or false, never nil" do
    sample_values.each do |value|
      assert_includes [true, false], FriendlyId.friendly_id?(value), "for #{value.inspect}"
      assert_includes [true, false], FriendlyId.unfriendly_id?(value), "for #{value.inspect}"
    end
  end

  # The Object methods answer nil where these answer false, which is the only
  # difference between them.
  test "the module functions agree with the Object methods" do
    sample_values.each do |value|
      assert_equal !!value.friendly_id?, FriendlyId.friendly_id?(value),
        "friendly_id? disagreed for #{value.inspect}"
      assert_equal !!value.unfriendly_id?, FriendlyId.unfriendly_id?(value),
        "unfriendly_id? disagreed for #{value.inspect}"
    end
  end

  # Nothing calls mark_as_unfriendly for these; the module function consults
  # UNFRIENDLY_CLASSES itself.
  test "the module functions do not depend on the Object patch" do
    assert_equal false, FriendlyId.friendly_id?(1)
    assert_equal false, FriendlyId.friendly_id?(:id)
    assert_equal false, FriendlyId.friendly_id?(nil)
    assert FriendlyId.friendly_id?("abc123")
    assert FriendlyId.unfriendly_id?(1)
  end

  # A numeric string is the case the two predicates cannot decide between, so
  # both are false and the finder tries the slug, then the primary key.
  test "a numeric string is neither friendly nor unfriendly" do
    assert_equal false, FriendlyId.friendly_id?("1")
    assert_equal false, FriendlyId.unfriendly_id?("1")
  end
end
