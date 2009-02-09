class Person < ActiveRecord::Base

  belongs_to :country
  has_friendly_id :name, :use_slug => true, :scope => :country

end