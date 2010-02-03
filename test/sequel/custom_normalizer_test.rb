require File.dirname(__FILE__) + "/test_helper"

module FriendlyId
  module Test
    module Sequel

      class CustomNormalizerTest < ::Test::Unit::TestCase

        include FriendlyId::Test::Sequel::Core
        include FriendlyId::Test::Sequel::Slugged
        include FriendlyId::Test::CustomNormalizer

        def klass
          Person
        end

      end
    end
  end
end