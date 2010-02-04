require File.dirname(__FILE__) + "/test_helper"

module FriendlyId
  module Test
    module Sequel
      
      # Core tests for any sequel model using FriendlyId.
      module Core

        def teardown
          klass.delete
          other_class.delete
          FriendlyId::Sequel::Slug.delete
        end

        def find_method
          :[]
        end

        def create_method
          :create
        end

        def delete_all_method
          :destroy
        end

        def save_method
          :save
        end

        def validation_exceptions
          ::Sequel::ValidationFailed
        end

      end
    end
  end
end
