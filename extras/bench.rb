$:.unshift File.expand_path("../lib", File.dirname(__FILE__))
$:.unshift File.expand_path(File.dirname(__FILE__))
$:.uniq!

require "extras"
require 'rbench'
FACTOR = 10

RBench.run(TIMES) do

  column :times
  column :default
  column :no_slug
  column :slug
  column :cached_slug

  report 'find model by id', (TIMES * FACTOR).ceil do
    default { User.find(get_id) }
    no_slug { User.find(USERS.rand) }
    slug { Post.find(POSTS.rand) }
    cached_slug { District.find(DISTRICTS.rand) }
  end

  report 'find model using array of ids', (TIMES * FACTOR).ceil do
    default { User.find(get_id(2)) }
    no_slug { User.find(USERS.rand(2)) }
    slug { Post.find(POSTS.rand(2)) }
    cached_slug { District.find(DISTRICTS.rand(2)) }
  end

  report 'find model using id, then to_param', (TIMES * FACTOR).ceil do
    default { User.find(get_id).to_param }
    no_slug { User.find(USERS.rand).to_param }
    slug { Post.find(POSTS.rand).to_param }
    cached_slug { District.find(DISTRICTS.rand).to_param }
  end

  summary 'Total'

end