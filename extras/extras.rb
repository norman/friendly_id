#!/usr/bin/env ruby -KU
require File.dirname(__FILE__) + '/../test/test_helper'
require File.dirname(__FILE__) + '/../test/active_record_adapter/ar_test_helper'
require 'ffaker'

TIMES = (ENV['N'] || 100).to_i
POSTS     = []
DISTRICTS = []
USERS     = []

User.delete_all
Post.delete_all
District.delete_all
Slug.delete_all

100.times do
  name = Faker::Name.name
  USERS     << (User.create!     :name => name).friendly_id
  POSTS     << (Post.create!     :name => name).friendly_id
  DISTRICTS << (District.create! :name => name).friendly_id
end

def get_id(returns = 1)
  (1..100).to_a.rand(returns)
end

class Array
  def rand(returns = 1)
    @return = []
    returns.times do
      until @return.length == returns do
        val = self[Kernel.rand(length)]
        @return << val unless @return.include? val
      end
    end
    return returns == 1 ? @return.first : @return
  end
end