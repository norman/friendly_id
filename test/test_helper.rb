$KCODE = "UTF8" if RUBY_VERSION < "1.9"
$VERBOSE = false

require "rubygems"
require "test/unit"
require "active_support"
require "active_support/testing/declarative"
require File.dirname(__FILE__) + "/../lib/friendly_id"

module FriendlyId
  module Test
    module Declarative
      def test(name, &block)
        define_method("test_#{name.gsub(/[^a-z0-9]/i, "_")}".to_sym, &block)
      end
      alias :should :test
    end
  end
end