$:.unshift File.expand_path("../lib", File.dirname(__FILE__))
$:.unshift File.expand_path(File.dirname(__FILE__))
$:.uniq!

$KCODE = "UTF8" if RUBY_VERSION < "1.9"
$VERBOSE = false
require "rubygems"
require "bundler/setup"
require "test/unit"
require "mocha"
require "active_support"
require "friendly_id"
require "friendly_id/test"
