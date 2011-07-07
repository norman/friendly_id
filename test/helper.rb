$LOAD_PATH << File.expand_path("../../lib", __FILE__)
$LOAD_PATH.uniq!

require "rubygems"
require "minitest/unit"
require "active_record"
require "active_support"
require "active_support/core_ext/module/delegation"

$VERBOSE = true

require "friendly_id"

# If you want to see the ActiveRecord log, invoke the tests using `rake test LOG=true`
if ENV["LOG"]
  require "logger"
  ActiveRecord::Base.logger = Logger.new($stdout)
end

module FriendlyId
  module Test

    def self.included(base)
      MiniTest::Unit.autorun
    end

    def transaction
      ActiveRecord::Base.transaction { yield ; raise ActiveRecord::Rollback }
    end

    def with_instance_of(*args)
      klass = args.shift
      args[0] ||= {:name => "a"}
      transaction { yield klass.create!(*args) }
    end

    module Database
      extend self

      def connect
        ActiveRecord::Base.establish_connection config
      end

      def config
        YAML::load(File.open(config_file))
      end

      def config_file
        File.expand_path("../config/#{driver}.yml", __FILE__)
      end

      def driver
        (ENV["DB"] or "sqlite3").downcase
      end
    end
  end
end

class Module
  def test(name, &block)
    define_method("test_#{name.gsub(/[^a-z0-9]/i, "_")}".to_sym, &block)
  end
end

["shared", "schema"].each {|f| require File.expand_path("../#{f}", __FILE__)}

FriendlyId::Test::Database.connect

class Author < ActiveRecord::Base
  has_friendly_id :name
end

class Book < ActiveRecord::Base
  has_friendly_id :name
end
