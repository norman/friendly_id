require "helper"

# The half of the sequential slug feature that does not touch the database.
# Calculator finds the conflicting slugs; this decides what the next slug is.
class SequenceCalculatorTest < TestCaseClass
  include FriendlyId::Test

  def next_slug(slug, conflicts, separator: "-")
    FriendlyId::SequenceCalculator.new.call(slug, conflicts, separator: separator)
  end

  test "starts at 2 when only the unnumbered slug exists" do
    assert_equal "foo-2", next_slug("foo", ["foo"])
  end

  test "continues from the highest existing sequence" do
    assert_equal "foo-4", next_slug("foo", %w[foo foo-2 foo-3])
  end

  test "does not assume the conflicts are ordered" do
    assert_equal "foo-11", next_slug("foo", %w[foo-10 foo-2 foo])
  end

  test "ignores conflicts that do not derive from the candidate" do
    assert_equal "foo-2", next_slug("foo", %w[foo foobar-9 other-3])
  end

  # The pattern is anchored at the front, so a longer slug that merely ends with
  # the candidate is not one of its sequenced forms.
  test "ignores a conflict that merely ends with the candidate" do
    assert_equal "foo-2", next_slug("foo", %w[foo barfoo-7])
  end

  # A separator of "+" unescaped gives /foo+(\d+)\z/, which does not match
  # "foo+2" at all, so the sequence resets and "foo+2" is handed out again.
  test "sequences correctly with a metacharacter separator" do
    assert_equal "foo+3", next_slug("foo", %w[foo foo+2], separator: "+")
  end

  # Unescaped, "." matches any character, so "foo-7" would count towards the
  # sequence for a candidate separated by ".".
  test "treats a metacharacter separator literally" do
    assert_equal "foo.2", next_slug("foo", %w[foo foo-7], separator: ".")
  end

  test "treats metacharacters in the slug literally" do
    assert_equal "a+b-2", next_slug("a+b", %w[a+b aab-9])
  end

  # A custom normalize_friendly_id can emit brackets. Unescaped, an unbalanced
  # one raises RegexpError rather than simply failing to match.
  test "survives an unbalanced bracket in the slug" do
    assert_equal "foo(-2", next_slug("foo(", ["foo("])
  end
end
