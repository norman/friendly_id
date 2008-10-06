$:.unshift(File.dirname(__FILE__) + '/../lib')

ENV['RAILS_ENV'] = 'test'

require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'active_record/fixtures'
require 'action_controller/test_process'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

db_adapter = ENV['DB']

# no db passed, try one of these fine config-free DBs before bombing.
db_adapter ||= 
  begin
    require 'rubygems'
    require 'sqlite3'
    'sqlite3'
  rescue MissingSourceFile
    begin
      require 'sqlite'
      'sqlite'
    rescue MissingSourceFile
    end
  end

if db_adapter.nil?
  raise 'No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite3 or Sqlite.'
end

ActiveRecord::Base.establish_connection(config[db_adapter])

load(File.dirname(__FILE__) + "/schema.rb")

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

  protected

end