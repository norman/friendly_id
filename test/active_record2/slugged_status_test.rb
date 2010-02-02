require File.dirname(__FILE__) + '/core'
require File.dirname(__FILE__) + '/slugged'

module FriendlyId
  module Test
    module ActiveRecord2

      class StatusTest < ::Test::Unit::TestCase

        extend FriendlyId::Test::Declarative

        test "should default to not friendly" do
          assert !status.friendly?
        end

        test "should default to numeric" do
          assert status.numeric?
        end

        test "should be friendly if slug is set" do
          status.slug = $slug_class.new
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
          status.slug = $slug_class.new(:sluggable => instance)
          assert !status.current?
        end

        test "should be best if it is current" do
          status.slug = instance.slug
          assert status.best?
        end

        test "should be best if it is numeric, but record has not slug" do
          instance.slugs = []
          instance.slug = nil
          assert status.best?
        end
        
        def instance
          @instance ||= Post.create! :name => "hello world"
        end

        def status
          @status ||= instance.friendly_id_status
        end

      end
    end
  end
end

