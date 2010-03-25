require File.dirname(__FILE__) + '/test_helper'

module FriendlyId
  module Test
    module AcktiveRecord

      class StiTest < ::Test::Unit::TestCase

        include FriendlyId::Test::Generic
        include FriendlyId::Test::Slugged
        include FriendlyId::Test::AcktiveRecord::Slugged
        include FriendlyId::Test::AcktiveRecord::Core

        def klass
          Novel
        end

      end

    end
  end
end