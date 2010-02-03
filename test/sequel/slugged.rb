require File.dirname(__FILE__) + "/test_helper"

module FriendlyId
  module Test
    module Sequel

      module Slugged

        def klass
          Post
        end

        def other_class
          City
        end

        def instance
          @instance ||= klass.send(create_method, :name => "hello world")
        end

      end
    end
  end
end