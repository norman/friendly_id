require File.dirname(__FILE__) + '/test_helper'

module FriendlyId
  module Test
    module AcktiveRecord

      class CustomNormalizerTest < ::Test::Unit::TestCase

        include FriendlyId::Test::AcktiveRecord::Core
        include FriendlyId::Test::AcktiveRecord::Slugged
        include FriendlyId::Test::CustomNormalizer

        def klass
          Person
        end

      end
    end
  end
end