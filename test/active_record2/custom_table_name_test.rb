require File.dirname(__FILE__) + '/core'
require File.dirname(__FILE__) + '/slugged'

module FriendlyId
  module Test
    module ActiveRecord2

      class CustomTableNameTest < ::Test::Unit::TestCase

        include Core
        include Slugged

        def klass
          Place
        end

      end

    end
  end
end
