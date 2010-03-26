require File.dirname(__FILE__) + '/test_helper'


#   scope :hello, :conditions => {"books.name" => "hello world"}
#   scope :friendly, lambda { |name| {:conditions => {"slugs.name" => name }, :include => :slugs}}
#
#   def self.find(*args, &block)
#     if FriendlyId::Finders::Base.friendly?(args.first)
#       puts "doing friendly find with #{args.first}"
#       self.friendly(args.shift).first(*args)
#     else
#       super
#     end
#   end
#
# end

module FriendlyId
  module Test
    module AcktiveRecord

      class StiTest < ::Test::Unit::TestCase

      #   def test_temp
      #     instance = Post.create(:name => "hello world")
      #     p instance.class.find(instance.friendly_id)
      #   end
      end

    end
  end
end
