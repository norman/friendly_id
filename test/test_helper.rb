$:.unshift(File.dirname(__FILE__) + '/../lib')
$VERBOSE = false

ENV['RAILS_ENV'] = 'test'
require File.dirname(__FILE__) + '/rails/2.x/config/environment.rb'
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

require 'test/unit'
require 'active_record/fixtures'
require 'action_controller/test_process'
require 'sqlite3'
require 'slug'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection

silence_stream(STDOUT) do
  load(File.dirname(__FILE__) + "/schema.rb")
end

Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures"
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)

class Test::Unit::TestCase #:nodoc:
  include ActionController::TestProcess
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end
