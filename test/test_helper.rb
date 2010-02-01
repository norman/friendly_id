$KCODE = "UTF8" if RUBY_VERSION < "1.9"
$VERBOSE = false

require "rubygems"
require "test/unit"
require "active_support"
require "active_support/testing/declarative"
require File.dirname(__FILE__) + "/../lib/friendly_id"