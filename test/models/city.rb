class City < ActiveRecord::Base
  attr_accessible :name
  has_friendly_id :name, :use_slug => true, :cache_column => 'my_slug'
end
