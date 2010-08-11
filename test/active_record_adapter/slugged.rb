require File.expand_path("../ar_test_helper", __FILE__)

module FriendlyId
  module Test
    module ActiveRecordAdapter
      module Slugged

        test "should allow eager loading of slugs" do
          assert_nothing_raised do
            klass.find(instance.friendly_id, :include => :slugs)
          end

          assert_nothing_raised do
            klass.find(instance.friendly_id, :include => :slug)
          end
        end

        def klass
          Post
        end

        def other_class
          District
        end

        def instance
          @instance ||= klass.create! :name => "hello world"
        end

      end
    end
  end
end
