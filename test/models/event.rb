class Event < ActiveRecord::Base
  has_friendly_id :event_date, :use_slug => true
end