require File.dirname(__FILE__) + "/test_helper"

module FriendlyId
  module Test

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