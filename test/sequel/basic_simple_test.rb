require File.dirname(__FILE__) + "/test_helper"
require File.dirname(__FILE__) + "/simple"


module FriendlyId
  module Test
    module Sequel
      class BasicSimpleTest < ::Test::Unit::TestCase
        include Core
        include Simple
      end
    end
  end
end