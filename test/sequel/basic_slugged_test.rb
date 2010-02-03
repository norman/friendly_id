require File.dirname(__FILE__) + "/test_helper"

module FriendlyId
  module Test
    module Sequel
      class BasicSimpleTest < ::Test::Unit::TestCase
        extend FriendlyId::Test::Declarative
        
        test "should create instance" do
          Post.create :name => "hello world"
        end
        
      end
    end
  end
end