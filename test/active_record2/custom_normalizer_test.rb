require File.dirname(__FILE__) + '/test_helper'

module FriendlyId
  module Test
    module ActiveRecord2

      class CustomNormalizerTest < ::Test::Unit::TestCase

        include FriendlyId::Test::ActiveRecord2::Core
        include FriendlyId::Test::ActiveRecord2::Slugged
        include FriendlyId::Test::CustomNormalizer

        def klass
          Person
        end

      end
    end
  end
end