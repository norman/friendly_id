require File.expand_path("../ar_test_helper", __FILE__)

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