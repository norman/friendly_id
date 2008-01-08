class Post < ActiveRecord::Base
  has_friendly_id :column => :name, :use_slug => true
end
