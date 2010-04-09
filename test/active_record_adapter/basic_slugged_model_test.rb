require File.expand_path('../ar_test_helper', __FILE__)

module FriendlyId
  module Test
    module ActiveRecordAdapter
      class BasicSluggedModelTest < ::Test::Unit::TestCase
        include FriendlyId::Test::Generic
        include FriendlyId::Test::Slugged
        include FriendlyId::Test::ActiveRecordAdapter::Slugged
        include FriendlyId::Test::ActiveRecordAdapter::Core
      end
    end
  end
end
