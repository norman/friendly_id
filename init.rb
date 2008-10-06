require 'iconv'
require 'friendly_id'

ActiveRecord::Base.extend Randomba::FriendlyId::ClassMethods
