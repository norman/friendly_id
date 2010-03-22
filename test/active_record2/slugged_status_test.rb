require File.dirname(__FILE__) + '/test_helper'


module FriendlyId
  module Test
    module ActiveRecord2

      class StatusTest < ::Test::Unit::TestCase

        include FriendlyId::Test::Status
        include FriendlyId::Test::SluggedStatus

        def klass
          Post
        end

        def instance
          @instance ||= klass.create! :name => "hello world"
        end

      end
    end
  end
end

