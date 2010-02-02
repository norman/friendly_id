require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../generic'

module FriendlyId
  module Test
    module Sequel
      module Core

        extend FriendlyId::Test::Declarative
        include Generic

        def teardown
          klass.delete
          other_class.delete
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

        def validation_exceptions
          ::Sequel::ValidationFailed
        end

      end
    end
  end
end
