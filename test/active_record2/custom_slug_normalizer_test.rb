require File.dirname(__FILE__) + '/core'
require File.dirname(__FILE__) + '/slugged'

module FriendlyId
  module Test
    module ActiveRecord2

      class CustomSlugNormalizerTest < ::Test::Unit::TestCase

        extend Declarative
        include Core
        include Slugged

        def klass
          Person
        end

        def teardown
          klass.delete_all
          Slug.delete_all
        end

        should "invoke the block code" do
          assert_equal "JOE SCHMOE", klass.create!(:name => "Joe Schmoe").friendly_id
        end

        should "respect the max_length option" do
          klass.friendly_id_config.stubs(:max_length).returns(3)
          assert_equal "JOE", klass.create!(:name => "Joe Schmoe").friendly_id
        end

        test "creation should raise an error if the friendly_id text is reserved" do
          klass.friendly_id_config.stubs(:reserved_words).returns(["JOE"])
          assert_raises FriendlyId::ReservedError do
            klass.create!(:name => "Joe")
          end
        end

        test "should allow the same friendly_id across models" do end

      end
    end
  end
end