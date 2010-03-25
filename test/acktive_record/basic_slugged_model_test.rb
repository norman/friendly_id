require File.dirname(__FILE__) + '/test_helper'

module FriendlyId
  module Test
    module AcktiveRecord
      class BasicSluggedModelTest < ::Test::Unit::TestCase
        include FriendlyId::Test::Generic
        include FriendlyId::Test::Slugged
        include FriendlyId::Test::AcktiveRecord::Slugged
        include FriendlyId::Test::AcktiveRecord::Core
      end
    end
  end
end
