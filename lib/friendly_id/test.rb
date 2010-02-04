Module.send :include, Module.new {
  def test(name, &block)
    define_method("test_#{name.gsub(/[^a-z0-9]/i, "_")}".to_sym, &block)
  end
  alias :should :test
}

module FriendlyId
  module Test

    # Tests for any model that implements FriendlyId. Any test that tests model
    # features should include this module.
    module Generic

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

    # Tests for any model that implements slugs.
    module Slugged

      test "should have a slug" do
        assert_not_nil instance.slug
      end

      test "should not make a new slug unless the friendly_id method value has changed" do
        instance.note = instance.note.to_s << " updated"
        instance.send save_method
        assert_equal 1, instance.slugs.size
      end

      test "should make a new slug if the friendly_id method value has changed" do
        instance.name = "Changed title"
        instance.send save_method
        assert_equal 2, instance.slugs.size
      end

      test "should be able to reuse an old friendly_id without incrementing the sequence" do
        old_title = instance.name
        old_friendly_id = instance.friendly_id
        instance.name = "A changed title"
        instance.send save_method
        instance.name = old_title
        instance.send save_method
        assert_equal old_friendly_id, instance.friendly_id
      end

      test "should increment the slug sequence for duplicate friendly ids" do
        instance2 = klass.send(create_method, :name => instance.name)
        assert_match(/2\z/, instance2.friendly_id)
      end

      test "should find instance with a sequenced friendly_id" do
        instance2 = klass.send(create_method, :name => instance.name)
        assert_equal instance2, klass.send(find_method, instance2.friendly_id)
      end

    end

    # Tests for models to ensure that they properly implement using the
    # +normalize_friendly_id+ method to allow developers to hook into the
    # slug string generation.
    module CustomNormalizer

      test "should invoke the custom normalizer" do
        assert_equal "JOE SCHMOE", klass.send(create_method, :name => "Joe Schmoe").friendly_id
      end

      test "should respect the max_length option" do
        klass.friendly_id_config.stubs(:max_length).returns(3)
        assert_equal "JOE", klass.send(create_method, :name => "Joe Schmoe").friendly_id
      end

      test "should raise an error if the friendly_id text is reserved" do
        klass.friendly_id_config.stubs(:reserved_words).returns(["JOE"])
        assert_raise(*[validation_exceptions].flatten) do
          klass.send(create_method, :name => "Joe")
        end

      end

    end
  end
end