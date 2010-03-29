require File.dirname(__FILE__) + '/test_helper'

module FriendlyId
  module Test
    module ActiveRecordAdapter

      class StiTest < ::Test::Unit::TestCase

        include FriendlyId::Test::Generic
        include FriendlyId::Test::Slugged
        include FriendlyId::Test::ActiveRecordAdapter::Slugged
        include FriendlyId::Test::ActiveRecordAdapter::Core

        def klass
          Novel
        end

      end

    end
  end
end