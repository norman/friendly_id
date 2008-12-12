class Country < ActiveRecord::Base
  has_many :people
  has_friendly_id :name, :use_slug => true
end