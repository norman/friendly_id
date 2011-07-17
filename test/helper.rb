$: << File.expand_path("../../lib", __FILE__)
$: << File.expand_path("../", __FILE__)
$:.uniq!

require "rubygems"
require "bundler/setup"
require "mocha"
require "minitest/unit"
require "active_support"
require "active_support/core_ext/module/delegation"
require "active_record"

if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start
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
      klass = args.shift
      args[0] ||= {:name => "a"}
      transaction { yield klass.create!(*args) }
    end

    module Database
      extend self

      def connect
        ActiveRecord::Base.establish_connection config
        version = ActiveRecord::VERSION::STRING
        driver  = FriendlyId::Test::Database.driver
        message = "Using #{RUBY_ENGINE} #{RUBY_VERSION} AR #{version} with #{driver}"
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
        @config ||= YAML::load(File.open(config_file))
      end

      def config_file
        File.expand_path("../config/#{driver}.yml", __FILE__)
      end

      def driver
        (ENV["DB"] or "sqlite3").downcase
      end

      def in_memory?
        config["database"] == ":memory:"
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