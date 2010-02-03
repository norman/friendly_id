$KCODE = "UTF8" if RUBY_VERSION < "1.9"
$VERBOSE = false

Module.send :include, Module.new {
  def test(name, &block)
    define_method("test_#{name.gsub(/[^a-z0-9]/i, "_")}".to_sym, &block)
  end
  alias :should :test
}

require "rubygems"
require "test/unit"
require "mocha"
require "active_support"
require File.dirname(__FILE__) + "/../lib/friendly_id"
require File.dirname(__FILE__) + "/generic"
require File.dirname(__FILE__) + "/slugged"
require File.dirname(__FILE__) + "/custom_normalizer"