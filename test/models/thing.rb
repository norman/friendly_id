require 'digest/sha1'
class Thing < ActiveRecord::Base
  has_friendly_id :name, :use_slug => true do |text|
    Digest::SHA1::hexdigest(text)
  end
end