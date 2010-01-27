#!/usr/bin/env ruby -KU
require File.dirname(__FILE__) + '/extras'
require 'rbench'
FACTOR = 20
RBench.run(TIMES) do

  column :times
  column :ar

  # report 'find model using id', (TIMES * FACTOR).ceil do
  #   ar { User.find(get_id) }
  # end
  # 
  report 'find model using array of ids', (TIMES * FACTOR).ceil do
    ar { User.find([get_id, get_id]) }
  end

  # report 'find unslugged model using friendly id', (TIMES * FACTOR).ceil do
  #   ar { User.find(USERS.rand) }
  # end
  # 
  report 'find unslugged model using array of friendly ids', (TIMES * FACTOR).ceil do
    ar { User.find([USERS.rand, USERS.rand]) }
  end

  # report 'find slugged model using friendly id', (TIMES * FACTOR).ceil do
  #   ar { Post.find(POSTS.rand) }
  # end
  # 
  report 'find slugged model using array of friendly ids', (TIMES * FACTOR).ceil do
    ar { Post.find([POSTS.rand, POSTS.rand]) }
  end

  # report 'find cached slugged model using friendly id', (TIMES * FACTOR).ceil do
  #   ar { District.find(DISTRICTS.rand) }
  # end
  # 
  report 'find cached slugged model using array of friendly ids', (TIMES * FACTOR).ceil do
    ar { District.find([DISTRICTS.rand, DISTRICTS.rand]) }
  end

  # report 'find model using id, then to_param', (TIMES * FACTOR).ceil do
  #   ar { User.find(get_id).to_param }
  # end
  # #
  # report 'find unslugged model using friendly id, then to_param', (TIMES * FACTOR).ceil do
  #   ar { User.find(USERS.rand).to_param }
  # end
  # #
  # report 'find slugged model using friendly id, then to_param', (TIMES * FACTOR).ceil do
  #   ar { Post.find(POSTS.rand).to_param }
  # end
  # #
  # report 'find cached slugged model using friendly id, then to_param', (TIMES * FACTOR).ceil do
  #   ar { District.find(DISTRICTS.rand).to_param }
  # end

  summary 'Total'
end