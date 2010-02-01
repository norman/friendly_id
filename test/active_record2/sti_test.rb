require File.dirname(__FILE__) + '/core'
require File.dirname(__FILE__) + '/slugged'

module FriendlyId
  module Test
    module ActiveRecord2

      class StiTest < ::Test::Unit::TestCase

        include Core
        include Slugged

        def klass
          Novel
        end

      end

    end
  end
end