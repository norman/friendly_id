require File.dirname(__FILE__) + '/core'
module FriendlyId
  module Test
    module ActiveRecord2
      module Slugged

        module SluggedTest
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

        module SluggedTests

          extend Declarative

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

        end

        class StatusTest < ::Test::Unit::TestCase

          extend Declarative
          include SluggedTest

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

          def status
            @status ||= instance.friendly_id_status
          end

        end

        class BasicTest < ::Test::Unit::TestCase
          include TestCore
          include SluggedTest
          include SluggedTests
        end

        class CustomTableNameTest < BasicTest
          def klass
            Place
          end
        end

        class StiTest < BasicTest
          def klass
            Novel
          end
        end

        class CachedSlugTest < BasicTest

          extend Declarative

          def klass
            District
          end

          def other_class
            Post
          end

          def cached_slug
            instance.send(cache_column)
          end

          def cache_column
            klass.friendly_id_config.cache_column
          end

          test "should have a cached_slug" do
            assert_equal cached_slug, instance.slug.to_friendly_id
          end

          test "should protect the cached slug value" do
            old_value = cached_slug
            instance.update_attributes(cache_column => "Madrid")
            instance.reload
            assert_equal old_value, cached_slug
          end

          test "should update the cached slug when updating the slug" do
            instance.update_attributes(:name => "new name")
            assert_equal instance.slug.to_friendly_id, cached_slug
          end

          test "should not update the cached slug column if it has not changed" do
            instance.note = "a note"
            instance.expects("#{cache_column}=".to_sym).never
            instance.save!
          end

          should "cache the incremented sequence for duplicate slug names" do
            instance_2 = klass.create!(:name => instance.name)
            assert_match(/2\z/, instance_2.send(cache_column))
          end

        end

        class CustomSlugNormalizerTest < ::Test::Unit::TestCase

          extend Declarative
          include SluggedTest

          def klass
            Person
          end

          def teardown
            klass.delete_all
            $slug_class.delete_all
          end

          should "invoke the block code" do
            assert_equal "JOE SCHMOE", klass.create!(:name => "Joe Schmoe").friendly_id
          end

          should "respect the max_length option" do
            klass.friendly_id_config.stubs(:max_length).returns(3)
            assert_equal "JOE", klass.create!(:name => "Joe Schmoe").friendly_id
          end

          should "respect the reserved option" do
            klass.friendly_id_config.stubs(:reserved_words).returns(["JOE"])
            assert_raises FriendlyId::ReservedError do
              klass.create!(:name => "Joe")
            end
          end

        end

      end
    end
  end
end

