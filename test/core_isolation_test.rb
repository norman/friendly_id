require "helper"

# FriendlyId's core must not depend on Active Record or Active Support, so that
# adapters for other persistence libraries can build on it.
#
# The main test suite loads Active Record before anything else, so this has to
# run in a subprocess to be meaningful.
class CoreIsolationTest < TestCaseClass
  include FriendlyId::Test

  LIB = File.expand_path("../lib", __dir__)

  def run_in_clean_process(source)
    script = ["$LOAD_PATH.unshift(#{LIB.inspect})", source].join("\n")
    output = IO.popen([RbConfig.ruby, "-e", script], err: [:child, :out], &:read)
    [output, $?.success?]
  end

  test "core loads without Active Record or Active Support" do
    output, ok = run_in_clean_process(<<~RUBY)
      require "friendly_id/core"
      abort "ActiveRecord was loaded" if defined?(ActiveRecord)
      abort "ActiveSupport was loaded" if defined?(ActiveSupport::VERSION)
      print "ok"
    RUBY
    assert ok, "expected a clean load, got: #{output}"
    assert_equal "ok", output
  end

  test "core exposes the ORM-agnostic classes" do
    output, ok = run_in_clean_process(<<~RUBY)
      require "friendly_id/core"
      %w[Candidates Configuration SlugGenerator SequenceCalculator Normalizers].each do |name|
        abort "missing \#{name}" unless FriendlyId.const_defined?(name)
      end
      print "ok"
    RUBY
    assert ok, "expected all core constants, got: #{output}"
    assert_equal "ok", output
  end

  test "core does not patch Object" do
    output, ok = run_in_clean_process(<<~RUBY)
      require "friendly_id/core"
      abort "Object#friendly_id? was defined" if Object.new.respond_to?(:friendly_id?)
      abort "Object#unfriendly_id? was defined" if Object.new.respond_to?(:unfriendly_id?)
      abort "Array was marked" if [].is_a?(FriendlyId::UnfriendlyUtils)
      print "ok"
    RUBY
    assert ok, "expected an unpatched Object, got: #{output}"
    assert_equal "ok", output
  end

  # The module functions have to give the same answers with or without the
  # deprecated patch, since core is what actually calls them.
  test "core predicates work without the Object patch" do
    output, ok = run_in_clean_process(<<~RUBY)
      require "friendly_id/core"
      cases = {
        123 => false, :id => false, {name: "joe"} => false, ["a = ?", "b"] => false,
        nil => false, true => false, false => false, 1.5 => false,
        "123" => nil, "abc123" => true, "hello-world" => true
      }
      cases.each do |value, expected|
        actual = FriendlyId.friendly_id?(value)
        abort "friendly_id?(\#{value.inspect}) was \#{actual.inspect}, expected \#{expected.inspect}" unless actual == expected
      end
      abort "unfriendly_id?(123) should be true" unless FriendlyId.unfriendly_id?(123)
      abort "unfriendly_id?('123') should be nil" unless FriendlyId.unfriendly_id?("123").nil?
      print "ok"
    RUBY
    assert ok, "expected the predicates to agree, got: #{output}"
    assert_equal "ok", output
  end

  test "requiring friendly_id still loads the Active Record adapter" do
    output, ok = run_in_clean_process(<<~RUBY)
      require "friendly_id"
      abort "Active Record adapter did not load" unless FriendlyId.respond_to?(:table_name_prefix)
      print "ok"
    RUBY
    assert ok, "expected the AR adapter to load, got: #{output}"
    assert_equal "ok", output
  end
end
