begin
  require 'friendly_id_datamapper'
rescue LoadError
  raise "To use FriendlyId's DataMapper adapter, please `gem install friendly_id_datamapper`"
end
