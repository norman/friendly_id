require File.dirname(__FILE__) + '/test_helper'


module FriendlyId
  module Test
    module ActiveRecord2

      class StatusTest < ::Test::Unit::TestCase

        test "should default to not friendly" do
          assert !status.friendly?
        end

        test "should default to numeric" do
          assert status.numeric?
        end

        test "should be friendly if slug is set" do
          status.slug = Slug.new
          assert status.friendly?
        end

        test "should be friendly if name is set" do
          status.name = "name"
          assert status.friendly?
        end

        test "should be current if current slug is set" do
          status.slug = instance.slug
          assert status.current?
        end

        test "should not be current if non-current slug is set" do
          status.slug = Slug.new(:sluggable => instance)
          assert !status.current?
        end

        test "should be best if it is current" do
          status.slug = instance.slug
          assert status.best?
        end

        test "should be best if it is numeric, but record has no slug" do
          instance.slugs = []
          instance.slug = nil
          assert status.best?
        end

        [:record, :name].each do |symbol|
          test "should have #{symbol} after find using friendly_id" do
            instance2 = klass.find(instance.friendly_id)
            assert_not_nil instance2.friendly_id_status.send(symbol)
          end
        end

        def klass
          Post
        end

        def instance
          @instance ||= klass.create! :name => "hello world"
        end

        def status
          @status ||= instance.friendly_id_status
        end

      end
    end
  end
end

