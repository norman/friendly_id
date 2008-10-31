class Post < ActiveRecord::Base
  has_friendly_id :name, :use_slug => true, :reserved => ['new', 'edit']
end
