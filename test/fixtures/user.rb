class User < ActiveRecord::Base
  has_friendly_id :login
end