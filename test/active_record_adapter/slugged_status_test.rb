require File.expand_path("../ar_test_helper", __FILE__)


module FriendlyId
  module Test
    module ActiveRecordAdapter

      class StatusTest < ::Test::Unit::TestCase

        include FriendlyId::Test::Status
        include FriendlyId::Test::SluggedStatus

        def klass
          Post
        end

        def instance
          @instance ||= klass.create! :name => "hello world"
        end

        def find_method
          :find
        end

      end
    end
  end
end
