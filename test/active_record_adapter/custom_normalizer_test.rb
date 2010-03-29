require File.dirname(__FILE__) + '/test_helper'

module FriendlyId
  module Test
    module ActiveRecordAdapter

      class CustomNormalizerTest < ::Test::Unit::TestCase

        include FriendlyId::Test::ActiveRecordAdapter::Core
        include FriendlyId::Test::ActiveRecordAdapter::Slugged
        include FriendlyId::Test::CustomNormalizer

        def klass
          Person
        end

      end
    end
  end
end