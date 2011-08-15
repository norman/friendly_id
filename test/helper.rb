$: << File.expand_path("../../lib", __FILE__)
$: << File.expand_path("../", __FILE__)
$:.uniq!

require "rubygems"
require "bundler/setup"
require "mocha"
require "minitest/unit"
require "active_record"
require 'active_support/core_ext/time/conversions'
# require "active_support/core_ext/class"

if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start do
    add_filter "test/"
    add_filter "friendly_id/migration"
  end
end

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
      model_class = args.shift
      args[0] ||= {:name => "a"}
      transaction { yield model_class.create!(*args) }
    end

    module Database
      extend self

      def connect
        ActiveRecord::Base.establish_connection config[driver]
        version = ActiveRecord::VERSION::STRING
        driver  = FriendlyId::Test::Database.driver
        engine = RUBY_ENGINE rescue "ruby"
        message = "Using #{engine} #{RUBY_VERSION} AR #{version} with #{driver}"
        puts "-" * 72
        if in_memory?
          ActiveRecord::Migration.verbose = false
          Schema.up
          puts "#{message} (in-memory)"
        else
          puts message
        end
      end

      def config
        @config ||= YAML::load(File.open(File.expand_path("../databases.yml", __FILE__)))
      end

      def driver
        (ENV["DB"] or "sqlite3").downcase
      end

      def in_memory?
        config[driver]["database"] == ":memory:"
      end
    end
  end
end

class Module
  def test(name, &block)
    define_method("test_#{name.gsub(/[^a-z0-9']/i, "_")}".to_sym, &block)
  end
end

require "schema"
require "shared"
FriendlyId::Test::Database.connect