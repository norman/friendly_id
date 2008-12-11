if ENV['RAILS_VERSION']
  RAILS_GEM_VERSION = ENV['RAILS_VERSION']
end
require File.join(File.dirname(__FILE__), 'boot')
Rails::Initializer.run
require File.dirname(__FILE__) + '/../../../../init.rb'