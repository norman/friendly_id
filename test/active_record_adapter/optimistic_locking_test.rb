require File.expand_path("../ar_test_helper", __FILE__)

module FriendlyId
  module Test
    module ActiveRecordAdapter
      class OptimisticLockingTest < ::Test::Unit::TestCase
        test "should update the cached slug when updating the slug" do
          region = Region.create! :name => 'some name'
          assert_nothing_raised do
            region.update_attributes(:name => "new name")
          end
          assert_equal region.slug.to_friendly_id, region.cached_slug
        end
      end
    end
  end
end

