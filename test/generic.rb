require File.dirname(__FILE__) + '/test_helper'

module FriendlyId

  module Test

    module Generic

      extend FriendlyId::Test::Declarative

      def setup
        klass.send delete_all_method
      end

      def teardown
        klass.send delete_all_method
        # other_class.delete_all
      end

      def instance
        raise NotImplementedError
      end

      def klass
        raise NotImplementedError
      end

      def other_class
        raise NotImplementedError
      end
      
      def find_method
        raise NotImplementedError
      end
      
      def create_method
        raise NotImplementedError
      end
      
      def validation_exceptions
        return RuntimeError
      end

      test "models should have a friendly id config" do
        assert_not_nil klass.friendly_id_config
      end

      test "instances should have a friendly id" do
        assert_not_nil instance.friendly_id
      end

      test "instances should have a friendly id status" do
        assert_not_nil instance.friendly_id_status
      end

      test "instances should be findable by their friendly id" do
        assert_equal instance, klass.send(find_method, instance.friendly_id)
      end

      test "instances should be findable by their numeric id as an integer" do
        assert_equal instance, klass.send(find_method, instance.id.to_i)
      end

      test "instances should be findable by their numeric id as a string" do
        assert_equal instance, klass.send(find_method, instance.id.to_s)
      end

      test "creation should raise an error if the friendly_id text is reserved" do
        assert_raise(*[validation_exceptions].flatten) do
          klass.send(create_method, :name => "new")
        end
      end

      test "creation should raise an error if the friendly_id text is an empty string" do
        assert_raise(*[validation_exceptions].flatten) do
          klass.send(create_method, :name => "")
        end
      end

      test "creation should raise an error if the friendly_id text is a blank string" do
        assert_raise(*[validation_exceptions].flatten) do
          klass.send(create_method, :name => "   ")
        end
      end

      test "creation should raise an error if the friendly_id text is nil" do
        assert_raise(*[validation_exceptions].flatten) do
          klass.send(create_method, :name => nil)
        end
      end

      test "should allow the same friendly_id across models" do
        other_instance = other_class.send(create_method, :name => instance.name)
        assert_equal other_instance.friendly_id, instance.friendly_id
      end

    end
  end
end