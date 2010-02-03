require(File.dirname(__FILE__) + "/test_helper")

module FriendlyId

  module Test

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
  end
end