require "rubygems"
require "bundler/setup"
require "active_record"
require "active_support"
require "friendly_id"
$VERBOSE = true

ActiveRecord::Migration.verbose = false

# Change the connection args as you see fit to test against different adapters.
ActiveRecord::Base.establish_connection \
  :adapter  => "sqlite3",
  :database => ":memory:"

# If you want to see the ActiveRecord log, invoke the tests using `rake test LOG=true`
if ENV["LOG"]
  require "logger"
  ActiveRecord::Base.logger = Logger.new($stdout)
end

User, Book = ["users", "books"].map do |table_name|
  ActiveRecord::Migration.create_table table_name do |t|
    t.string  :name
    t.boolean :active
  end
  Class.new(ActiveRecord::Base)
end

def transaction
  ActiveRecord::Base.transaction { yield ; raise ActiveRecord::Rollback }
end

def with_instance_of(*args)
  klass = args.shift
  args[0] ||= {:name => "a"}
  transaction { yield klass.create!(*args) }
end

def migration
  yield ActiveRecord::Migration
end