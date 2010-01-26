#!/usr/bin/env ruby -KU
require File.dirname(__FILE__) + '/extras'
require 'rbench'

RBench.run(TIMES) do

  column :times
  column :ar
  
  report 'find model using id', (TIMES * FACTOR).ceil do
    ar { User.find(id ||= get_id) }
  end
  
  report 'find model using array of ids', (TIMES * FACTOR).ceil do
    ar { User.find(ids ||= [get_id, get_id]) }
  end
  
  report 'find unslugged model using friendly id', (TIMES * FACTOR).ceil do
    ar { User.find(id ||= USERS.rand) }
  end
  
  report 'find unslugged model using array of friendly ids', (TIMES * FACTOR).ceil do
    ar { User.find(ids ||= [USERS.rand, USERS.rand]) }
  end
  
  report 'find slugged model using friendly id', (TIMES * FACTOR).ceil do
    ar { Post.find(id ||= POSTS.rand) }
  end
  
  report 'find slugged model using array of friendly ids', (TIMES * FACTOR).ceil do
    ar { Post.find(id ||= [POSTS.rand, POSTS.rand]) }
  end
  
  report 'find model using id, then to_param', (TIMES * FACTOR).ceil do
    ar { User.find(id ||= get_id).to_param }
  end
  # 
  report 'find unslugged model using friendly id, then to_param', (TIMES * FACTOR).ceil do
    ar { User.find(id ||= USERS.rand).to_param }
  end
  # 
  report 'find slugged model using friendly id, then to_param', (TIMES * FACTOR).ceil do
    ar { Post.find(id ||= POSTS.rand).to_param }
  end
  # 
  report 'find cached slugged model using friendly id, then to_param', (TIMES * FACTOR).ceil do
    ar { District.find(id ||= DISTRICTS.rand).to_param }
  end

  summary 'Total'
end