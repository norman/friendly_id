require File.dirname(__FILE__) + "/test_helper"

module FriendlyId
  module Test
    module Sequel
      
      # Tests for Sequel models using FriendlyId without slugs.
      class BasicSimpleTest < ::Test::Unit::TestCase
        include FriendlyId::Test::Generic
        include FriendlyId::Test::Sequel::Core
        include FriendlyId::Test::Sequel::Simple
      end
    end
  end
end