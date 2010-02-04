$KCODE = "UTF8" if RUBY_VERSION < "1.9"
$VERBOSE = false

require "rubygems"
require "test/unit"
require "mocha"
require "active_support"
require File.dirname(__FILE__) + "/../lib/friendly_id"
require File.dirname(__FILE__) + "/../lib/friendly_id/test"