require File.dirname(__FILE__) + '/core'
module FriendlyId
  module Test
    module ActiveRecord2
      module Slugged

        extend FriendlyId::Test::Declarative

        test "should have a slug" do
          assert_not_nil instance.slug
        end

        test "should not make a new slug unless the friendly_id method value has changed" do
          instance.note = instance.note.to_s << " updated"
          instance.save!
          assert_equal 1, instance.slugs.size
        end

        test "should make a new slug if the friendly_id method value has changed" do
          instance.name = "Changed title"
          instance.save!
          assert_equal 2, instance.slugs.size
        end

        test "should be able to reuse an old friendly_id without incrementing the sequence" do
          old_title = instance.name
          old_friendly_id = instance.friendly_id
          instance.name = "A changed title"
          instance.save!
          instance.name = old_title
          instance.save!
          assert_equal old_friendly_id, instance.friendly_id
        end

        test "should allow eager loading of slugs" do
          assert_nothing_raised do
            klass.find(instance.friendly_id, :include => :slugs)
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

