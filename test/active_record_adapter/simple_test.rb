require File.expand_path('../test_helper', __FILE__)

module FriendlyId
  module Test
    module ActiveRecordAdapter
      module Simple

        module SimpleTest
          def klass
            @klass ||= User
          end

          def instance
            @instance ||= User.create! :name => "hello world"
          end

          def other_class
            Author
          end
        end

        class StatusTest < ::Test::Unit::TestCase

          include SimpleTest

          def setup
            User.delete_all
          end

          test "should default to not friendly" do
            assert !status.friendly?
          end

          test "should default to numeric" do
            assert status.numeric?
          end

          test "should be friendly if name is set" do
            status.name = "name"
            assert status.friendly?
          end

          test "should be best if it is numeric, but record has no friendly_id" do
            instance.send("#{klass.friendly_id_config.column}=", nil)
            assert status.best?
          end

          def status
            @status ||= instance.friendly_id_status
          end

        end

        class BasicTest < ::Test::Unit::TestCase
          include Core
          include SimpleTest
        end

      end
    end
  end
end

