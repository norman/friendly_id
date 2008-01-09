class User < ActiveRecord::Base
  has_friendly_id :column => :login
end