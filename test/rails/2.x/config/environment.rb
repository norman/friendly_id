if ENV['RAILS_VERSION']
  RAILS_GEM_VERSION = ENV['RAILS_VERSION']
end
require File.join(File.dirname(__FILE__), 'boot')
Rails::Initializer.run
ActiveRecord::Base.colorize_logging = false
require File.dirname(__FILE__) + '/../../../../rails/init.rb'