require "helper"

# The persistence-independent half of the sequential slug feature. Adapters find
# the conflicting slugs; this decides what the next slug should be.
class SequenceCalculatorTest < TestCaseClass
  include FriendlyId::Test

  def calculator(slug, separator = "-")
    FriendlyId::SequenceCalculator.new(slug, separator)
  end

  test "starts at 2 when only the unnumbered slug exists" do
    assert_equal "foo-2", calculator("foo").next_slug(["foo"])
  end

  test "continues from the highest existing sequence" do
    assert_equal "foo-4", calculator("foo").next_slug(%w[foo foo-2 foo-3])
  end

  test "does not assume the conflicts are ordered" do
    assert_equal "foo-11", calculator("foo").next_slug(%w[foo-10 foo-2 foo])
  end

  test "ignores conflicts that do not derive from the candidate" do
    assert_equal "foo-2", calculator("foo").next_slug(%w[foo foobar-9 other-3])
  end

  # The pattern is anchored at the front, so a longer slug that merely ends with
  # the candidate is not one of its sequenced forms.
  test "ignores a conflict that merely ends with the candidate" do
    assert_equal "foo-2", calculator("foo").next_slug(%w[foo barfoo-7])
  end

  # A separator is configurable and may be a regexp metacharacter. Unescaped, "."
  # would match any character, so "foo-2" would count towards "foo"'s sequence.
  test "treats a metacharacter separator literally" do
    assert_equal "foo.2", calculator("foo", ".").next_slug(%w[foo foo-7])
  end

  test "still sequences correctly with a metacharacter separator" do
    assert_equal "foo.3", calculator("foo", ".").next_slug(%w[foo foo.2])
  end

  test "treats metacharacters in the slug literally" do
    assert_equal "a+b-2", calculator("a+b").next_slug(%w[a+b aab-9])
  end

  # A custom normalizer can emit brackets. Unescaped, an unbalanced one raises
  # RegexpError rather than simply failing to match.
  test "survives an unbalanced bracket in the slug" do
    assert_equal "foo(-2", calculator("foo(").next_slug(["foo("])
  end
end
