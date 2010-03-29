begin
  require "friendly_id_sequel"
rescue LoadError
  raise "To use FriendlyId's Sequel adapter, please `gem install friendly_id_sequel`"
end